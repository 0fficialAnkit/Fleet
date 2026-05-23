import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error("Missing Supabase configuration.")
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    })

    const { full_name, email, password, phone, role_name, license_number } = await req.json()

    if (!email || !password || !role_name || !full_name) {
      throw new Error("Missing required fields: email, password, role_name, full_name")
    }

    // 1. Create user in Supabase Auth
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email: email,
      password: password,
      email_confirm: true,
      user_metadata: { full_name }
    })

    if (authError) throw authError

    const userId = authData.user.id

    // 2. Fetch role_id
    const { data: roleData, error: roleError } = await supabaseAdmin
      .from('roles')
      .select('id')
      .eq('role_name', role_name)
      .single()

    if (roleError) {
      // If role fetch fails, we might want to delete the created auth user to avoid dangling users
      await supabaseAdmin.auth.admin.deleteUser(userId)
      throw new Error(`Role not found: ${role_name}. Details: ${roleError.message}`)
    }

    const roleId = roleData.id

    // 3. Insert into public.users
    const profilePayload: any = {
      id: userId,
      full_name,
      email,
      role_id: roleId,
      status: 'active'
    }

    if (phone) profilePayload.phone = phone
    if (license_number) profilePayload.license_number = license_number

    const { data: profileData, error: profileError } = await supabaseAdmin
      .from('users')
      .insert([profilePayload])
      .select()
      .single()

    if (profileError) {
      // Cleanup auth user if profile creation fails
      await supabaseAdmin.auth.admin.deleteUser(userId)
      throw profileError
    }

    return new Response(
      JSON.stringify(profileData),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
