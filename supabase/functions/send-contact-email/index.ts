import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { SmtpClient } from 'https://deno.land/x/smtp@v0.7.0/mod.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { firstName, lastName, email, phone, message } = await req.json();

    const client = new SmtpClient();

    await client.connectTLS({
      hostname: 'smtp.office365.com',
      port: 587,
      username: 'info@reinhold-medizintechnik.de',
      password: Deno.env.get('SMTP_PASSWORD') || '',
    });

    await client.send({
      from: 'info@reinhold-medizintechnik.de',
      to: 'info@reinhold-medizintechnik.de',
      subject: 'Neue Kontaktanfrage über das Schulungsportal',
      content: `
        <html>
          <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
              <h2 style="color: #2563eb;">Neue Kontaktanfrage</h2>
              
              <div style="background-color: #f3f4f6; padding: 20px; border-radius: 8px; margin: 20px 0;">
                <p><strong>Name:</strong> ${firstName} ${lastName}</p>
                <p><strong>E-Mail:</strong> ${email}</p>
                <p><strong>Telefon:</strong> ${phone}</p>
                <p><strong>Nachricht:</strong></p>
                <p style="white-space: pre-wrap;">${message}</p>
              </div>
              
              <p style="color: #666; font-size: 14px;">
                Diese Nachricht wurde über das Kontaktformular des Schulungsportals gesendet.
              </p>
            </div>
          </body>
        </html>
      `,
      html: true,
    });

    await client.close();

    return new Response(
      JSON.stringify({ message: 'Email sent successfully' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error sending email:', error);
    return new Response(
      JSON.stringify({ error: 'Failed to send email' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});