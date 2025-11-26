const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendBookingNotification = functions.firestore
	.document("bookings/{bookingId}")
	.onCreate(async (snap, context) => {
		const bookingData = snap.data();
		const providerId = bookingData.providerId;

		if (!providerId) {
			console.log("Missing providerId in booking data");
			return;
		}

		try {
			// Get provider's FCM token
			const providerRef = admin
				.firestore()
				.collection("providers")
				.doc(providerId);
			const providerDoc = await providerRef.get();

			if (!providerDoc.exists) {
				console.log(`❌ No provider found with ID: ${providerId}`);
				return;
			}

			const fcmToken = providerDoc.data().fcmToken;

			if (!fcmToken) {
				console.log("No FCM token found for provider:", providerId);
				return;
			}

			const payload = {
				notification: {
					title: "New Booking Received!",
					body: `You have a new booking from ${
						bookingData.customerName || "a customer"
					}`,
					clickAction: "FLUTTER_NOTIFICATION_CLICK",
				},
				token: fcmToken,
			};
			await admin.messaging().send(payload);
			print(admin.messaging().send(payload));
			print(`✅ Push notification sent to provider: ${providerId}`);
		} catch (error) {
			console.error(
				`Error sending notification to provider ${providerId}:`,
				error
			);
		}
	});

exports.notifyBookingStatusChange = functions.firestore
	.document("bookings/{bookingId}")
	.onUpdate(async (change, context) => {
		const before = change.before.data();
		const after = change.after.data();

		// Check if time or date has changed
		const timeChanged = before.time !== after.time;
		const dateChanged = before.date !== after.date;
		const statusChanged = before.status !== after.status;

		if (!timeChanged && !dateChanged && !statusChanged) return null;

		const { customerId, providerId, status } = after;

		// Determine the recipient based on who initiated the change
		let recipientId;
		if (before.updatedBy === customerId) {
			recipientId = providerId;
		} else if (before.updatedBy === providerId) {
			recipientId = customerId;
		} else {
			console.log("Updated by an unknown entity. No notification sent.");
			return null;
		}

		// Fetch the recipient's FCM token
		const userRef = admin.firestore().collection("users").doc(recipientId);
		const userDoc = await userRef.get();

		if (!userDoc.exists) {
			console.log(`No user found with ID: ${recipientId}`);
			return null;
		}

		const fcmToken = userDoc.data().fcmToken;

		if (!fcmToken) {
			console.log(`No FCM token found for user: ${recipientId}`);
			return null;
		}

		// Construct the notification payload
		const payload = {
			notification: {
				title:
					dateChanged || timeChanged
						? "Booking Rescheduled"
						: "Booking Status Updated",
				body:
					dateChanged || timeChanged
						? `${after.customerName} rescheduled booking for ${after.serviceName} to ${after.date} at ${after.time}`
						: `The booking was ${status} by ${after.customerName} for booking of ${after.serviceName}`,
				clickAction: "FLUTTER_NOTIFICATION_CLICK",
			},
			token: fcmToken,
		};

		// Send the notification
		try {
			await admin.messaging().send(payload);
			console.log(`Notification sent to user: ${recipientId}`);
		} catch (error) {
			console.error(
				`Error sending notification to user ${recipientId}:`,
				error
			);
		}
	});

exports.sendNewOfferNotification = functions.firestore
	.document("offers/{offerId}")
	.onCreate((snap, context) => {
		const offer = snap.data();
		const payload = {
			notification: {
				title: "🎉 New Special Offer!",
				body: `${offer.title} - Tap to view now!`,
			},
			topic: "special_offers",
		};

		return admin.messaging().send(payload);
	});
