const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp();
const db = getFirestore();

/**
 * Server-side answer validation for MP (Hard rule #1 — the client never sees
 * `answers/{questionId}`, which `firestore.rules` denies outright; only this
 * function, running with admin credentials, can read it).
 *
 * Request: { questionId: string, selectedIndex: number }
 * Response: { isCorrect: boolean, correctIndex: number }
 *
 * Requires the caller to be signed in (anonymous auth is enough) so answers
 * can't be farmed by an anonymous script with no identity at all.
 */
exports.checkAnswer = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Sign in (even anonymously) before answering.');
  }

  const { questionId, selectedIndex } = request.data ?? {};
  if (typeof questionId !== 'string' || typeof selectedIndex !== 'number') {
    throw new HttpsError(
      'invalid-argument',
      'questionId (string) and selectedIndex (number) are required.',
    );
  }

  const snapshot = await db.collection('answers').doc(questionId).get();
  if (!snapshot.exists) {
    throw new HttpsError('not-found', `No answer recorded for question ${questionId}.`);
  }

  const { correctIndex } = snapshot.data();
  return { isCorrect: selectedIndex === correctIndex, correctIndex };
});
