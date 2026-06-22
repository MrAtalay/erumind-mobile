// One-off admin script: pushes assets/questions.json into Firestore.
//
// Usage:
//   node seed.js <path-to-service-account-key.json>
//
// Writes three collections:
//   - categories/{id}  -> { name, colorValue, description }
//   - questions/{id}   -> { categoryId, text, options, difficulty }  (no correctIndex)
//   - answers/{id}     -> { correctIndex }                          (locked by firestore.rules,
//                                                                     for the future Cloud Function)
//
// Never commit the service account key. Re-run after editing assets/questions.json
// to resync Firestore.

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const keyPathArg = process.argv[2];
if (!keyPathArg) {
  console.error('Usage: node seed.js <path-to-service-account-key.json>');
  process.exit(1);
}

const serviceAccount = JSON.parse(fs.readFileSync(path.resolve(keyPathArg), 'utf8'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const questionsJsonPath = path.resolve(__dirname, '..', '..', 'assets', 'questions.json');
const data = JSON.parse(fs.readFileSync(questionsJsonPath, 'utf8'));

async function main() {
  let batch = db.batch();
  let opsInBatch = 0;

  const queue = (ref, value) => {
    batch.set(ref, value);
    opsInBatch += 1;
  };

  for (const category of data.categories) {
    queue(db.collection('categories').doc(category.id), {
      name: category.name,
      colorValue: category.colorValue,
      description: category.description ?? null,
    });
  }

  for (const question of data.questions) {
    queue(db.collection('questions').doc(question.id), {
      categoryId: question.categoryId,
      text: question.text,
      options: question.options,
      difficulty: question.difficulty ?? 'medium',
    });
    queue(db.collection('answers').doc(question.id), {
      correctIndex: question.correctIndex,
    });
  }

  await batch.commit();
  console.log(
    `Seeded ${data.categories.length} categories, ${data.questions.length} questions ` +
      `(+ ${data.questions.length} locked answers).`,
  );
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
