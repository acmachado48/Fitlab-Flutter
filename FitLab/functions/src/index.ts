import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';

admin.initializeApp();

export const onCheckinWrite = functions.firestore
  .document('usuarios/{uid}/checkins/{checkinId}')
  .onWrite(async (change, context) => {
    // seus tipos explícitos para evitar erro no TS
    // change: functions.Change<functions.firestore.DocumentSnapshot>
    // context: functions.EventContext

    const uid = context.params.uid;

    const userRef = admin.firestore().collection('usuarios').doc(uid);
    const userSnap = await userRef.get();
    if (!userSnap.exists) {
      console.log('Usuário não encontrado:', uid);
      return null;
    }

    // lógica de prêmios ou atualizações aqui

    return null;
  });
