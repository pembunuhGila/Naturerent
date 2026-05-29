import { createClient } from '@supabase/supabase-js'
import { NextResponse } from 'next/server'

function getAdminClient() {
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY
  if (!serviceKey || serviceKey.length < 20) {
    return null
  }
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL,
    serviceKey,
    { auth: { autoRefreshToken: false, persistSession: false } }
  )
}

// GET /api/platform-settings — Fetch platform settings
export async function GET() {
  const supabase = getAdminClient()
  if (!supabase) {
    return NextResponse.json(
      { error: 'SUPABASE_SERVICE_ROLE_KEY belum dikonfigurasi di .env.local' },
      { status: 503 }
    )
  }

  const { data, error } = await supabase
    .from('platform_settings')
    .select('qris_image_url')
    .eq('id', 1)
    .single()

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 })
  }
  return NextResponse.json(data)
}

// PATCH /api/platform-settings — Update platform settings
export async function PATCH(request) {
  const supabase = getAdminClient()
  if (!supabase) {
    return NextResponse.json(
      { error: 'SUPABASE_SERVICE_ROLE_KEY belum dikonfigurasi di .env.local' },
      { status: 503 }
    )
  }

  const body = await request.json()
  const { error } = await supabase
    .from('platform_settings')
    .update(body)
    .eq('id', 1)

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 })
  }
  return NextResponse.json({ success: true })
}
