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
    const { email, code, sender } = await req.json();

    if (!email || !code || !sender) {
      return new Response(
        JSON.stringify({ error: 'Email, code and sender are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const client = new SmtpClient();

    await client.connectTLS({
      hostname: 'smtp.office365.com',
      port: 587,
      username: sender,
      password: Deno.env.get('SMTP_PASSWORD') || '',
    });

    await client.send({
      from: sender,
      to: email,
      subject: 'Ihr Verifizierungscode für das Schulungsportal',
      content: `
        <html>
          <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
              <h2 style="color: #2563eb;">Willkommen im Schulungsportal</h2>
              <p>Sehr geehrter Benutzer,</p>
              <p>vielen Dank für Ihre Registrierung im Schulungsportal der Reinhold Medizintechnik GmbH.</p>
              <p>Ihr Verifizierungscode lautet:</p>
              <div style="background-color: #f3f4f6; padding: 20px; border-radius: 8px; text-align: center; margin: 20px 0;">
                <span style="font-size: 24px; font-weight: bold; letter-spacing: 4px;">${code}</span>
              </div>
              <p>Bitte geben Sie diesen Code auf der Registrierungsseite ein, um Ihre E-Mail-Adresse zu bestätigen.</p>
              <p>Der Code ist 24 Stunden gültig.</p>
              <p style="margin-top: 40px; font-size: 14px; color: #666;">
                Mit freundlichen Grüßen<br>
                Ihr Team von Reinhold Medizintechnik
              </p>
            </div>
          </body>
        </html>
      `,
      html: true,
    });

    await client.close();

    return new Response(
      JSON.stringify({ message: 'Verification email sent successfully' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error sending email:', error);
    return new Response(
      JSON.stringify({ error: 'Failed to send verification email' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});