import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3"
import nodemailer from "npm:nodemailer"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const gmailUser = Deno.env.get('GMAIL_USER')
    const gmailPassword = Deno.env.get('GMAIL_APP_PASSWORD')

    if (!gmailUser || !gmailPassword) {
        throw new Error("Missing GMAIL_USER or GMAIL_APP_PASSWORD environment variables.")
    }

    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: gmailUser,
        pass: gmailPassword
      }
    })

    const body = await req.json()
    let userId = body.userId || body.user_id
    const email = body.email
    const fullName = body.fullName || body.full_name

    if (!userId || !email || !fullName) {
        throw new Error(`Missing required parameters. Received: ${JSON.stringify(body)}`)
    }

    userId = String(userId).toLowerCase()

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    // Generate a random 12 character password
    const newPassword = generateRandomPassword(12)

    // Update user password in Auth
    const { data: user, error: updateError } = await supabaseAdmin.auth.admin.updateUserById(
      userId,
      { password: newPassword }
    )

    if (updateError) {
      console.error("Error updating user password:", updateError)
      throw updateError
    }

    // Send Email using Gmail SMTP
    const mailOptions = {
        from: `"Fleet App" <${gmailUser}>`,
        to: email,
        subject: 'Your Fleet App Login Credentials',
        html: `
            <h2>Welcome to the Fleet App, ${fullName}!</h2>
            <p>Your login credentials have been shared with you by your Fleet Manager.</p>
            <p><strong>Email:</strong> ${email}</p>
            <p><strong>Password:</strong> ${newPassword}</p>
            <br/>
            <p>Please log in to access your portal.</p>
        `
    }

    await transporter.sendMail(mailOptions)

    return new Response(
      JSON.stringify({ success: true, message: "Credentials sent successfully." }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 },
    )
  }
})

function generateRandomPassword(length: number): string {
    const uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    const lowercase = "abcdefghijklmnopqrstuvwxyz";
    const numbers = "0123456789";
    const symbols = "!@#$%^&*";
    
    // Ensure at least one of each to meet common password requirements
    let password = "";
    password += uppercase.charAt(Math.floor(Math.random() * uppercase.length));
    password += lowercase.charAt(Math.floor(Math.random() * lowercase.length));
    password += numbers.charAt(Math.floor(Math.random() * numbers.length));
    password += symbols.charAt(Math.floor(Math.random() * symbols.length));
    
    const allChars = uppercase + lowercase + numbers + symbols;
    for (let i = password.length; i < length; ++i) {
        password += allChars.charAt(Math.floor(Math.random() * allChars.length));
    }
    
    // Shuffle the password
    return password.split('').sort(() => 0.5 - Math.random()).join('');
}
