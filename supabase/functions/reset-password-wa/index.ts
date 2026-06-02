import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function normalizePhone(value: unknown) {
  const digits = String(value ?? '').replace(/\D/g, '');
  if (digits.startsWith('62')) return `0${digits.substring(2)}`;
  if (digits.startsWith('8')) return `0${digits}`;
  return digits;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return json({ message: 'Method tidak didukung.' }, 405);
  }

  try {
    const { email, no_wa, password_baru } = await req.json();
    const normalizedEmail = String(email ?? '').trim().toLowerCase();
    const normalizedNoWa = normalizePhone(no_wa);
    const passwordBaru = String(password_baru ?? '');

    if (!normalizedEmail || !normalizedEmail.includes('@')) {
      return json({ message: 'Format email tidak valid.' }, 400);
    }

    if (normalizedNoWa.length < 9) {
      return json({ message: 'Nomor WA tidak valid.' }, 400);
    }

    if (passwordBaru.length < 8) {
      return json(
        { message: 'Password baru terlalu lemah. Gunakan minimal 8 karakter.' },
        400,
      );
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !serviceRoleKey) {
      return json(
        { message: 'Konfigurasi service role Supabase belum tersedia.' },
        500,
      );
    }

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data: profile, error: profileError } = await admin
      .from('users')
      .select('id, email, no_wa, phone')
      .eq('email', normalizedEmail)
      .maybeSingle();

    if (profileError) {
      return json({ message: profileError.message }, 500);
    }

    if (!profile) {
      return json({ message: 'Email tidak ditemukan atau belum terdaftar.' }, 404);
    }

    const storedNoWa = normalizePhone(profile.phone ?? profile.no_wa);
    if (!storedNoWa || storedNoWa !== normalizedNoWa) {
      return json(
        { message: 'Nomor WA tidak cocok dengan akun tersebut.' },
        401,
      );
    }

    const { error: updateError } = await admin.auth.admin.updateUserById(
      profile.id,
      { password: passwordBaru },
    );

    if (updateError) {
      return json({ message: updateError.message }, 500);
    }

    return json({ message: 'Password berhasil direset.' });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return json({ message }, 500);
  }
});
