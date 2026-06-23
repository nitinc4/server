const express = require('express');
const router = express.Router();
const sendEmail = require('../utils/email');

// @route   POST /api/contact
// @desc    Send contact form message via email
router.post('/', async (req, res) => {
  const { name, email, subject, message, phone } = req.body;
  const customerName = name || 'Valued Customer';
  const customerEmail = email || 'No email provided';
  const customerPhone = phone || 'Not provided';
  const customerSubject = subject || 'No Subject';
  const customerMessage = message || 'No message content';

  console.log('Contact form submission received:', { name, email, subject, phone });

  try {
    const adminEmail = process.env.EMAIL_USER;

    // 1. Send email to Admin
    await sendEmail({
      to: adminEmail,
      subject: `New Contact Form Submission: ${customerSubject}`,
      html: `
        <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; border: 1px solid #eee; border-radius: 10px; overflow: hidden;">
          <div style="background-color: #059669; color: white; padding: 20px; text-align: center;">
            <h1 style="margin: 0;">New Inquiry</h1>
          </div>
          <div style="padding: 20px;">
            <p><strong>Name:</strong> ${customerName}</p>
            <p><strong>Email:</strong> ${customerEmail}</p>
            <p><strong>Phone:</strong> ${customerPhone}</p>
            <p><strong>Subject:</strong> ${customerSubject}</p>
            <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;" />
            <p><strong>Message:</strong></p>
            <div style="background-color: #f9f9f9; padding: 15px; border-radius: 5px; white-space: pre-wrap;">${customerMessage}</div>
          </div>
          <div style="background-color: #f4f4f4; padding: 10px; text-align: center; font-size: 12px; color: #777;">
            Sent from Zudo Website Contact Form
          </div>
        </div>
      `
    });

    // 2. Send confirmation email to User
    if (email) {
      await sendEmail({
        to: email,
        subject: 'We received your message!',
        html: `
          <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; border: 1px solid #eee; border-radius: 10px; overflow: hidden;">
            <div style="background-color: #059669; color: white; padding: 20px; text-align: center;">
              <h1 style="margin: 0;">Hello ${customerName}!</h1>
            </div>
            <div style="padding: 20px;">
              <p>Thank you for reaching out to Zudo. We have received your inquiry and our team will get back to you as soon as possible.</p>
              <div style="background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin: 20px 0;">
                <p style="margin: 0; font-style: italic;">"We're processing your request. Most inquiries are answered within 24 hours."</p>
              </div>
              <p>Best regards,<br/><strong>Team Zudo</strong></p>
            </div>
            <div style="background-color: #f4f4f4; padding: 10px; text-align: center; font-size: 12px; color: #777;">
              This is an automated response. Please do not reply directly to this email.
            </div>
          </div>
        `
      });
    }

    res.json({ message: 'Message sent successfully' });
  } catch (error) {
    console.error('Contact Form Email Error:', error);
    res.status(500).json({ message: 'Failed to send message. Please try again later.' });
  }
});

module.exports = router;
