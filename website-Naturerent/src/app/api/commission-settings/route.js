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

export async function GET() {
  const supabase = getAdminClient()
  if (!supabase) {
    return NextResponse.json(
      { error: 'SUPABASE_SERVICE_ROLE_KEY belum dikonfigurasi di .env.local' },
      { status: 503 }
    )
  }

  const { data, error } = await supabase
    .from('commission_settings')
    .select('percentage')
    .order('updated_at', { ascending: false })
    .limit(1)
    .maybeSingle()

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 })
  }
  return NextResponse.json(data || { percentage: 12.5 })
}

export async function POST(request) {
  const supabase = getAdminClient()
  if (!supabase) {
    return NextResponse.json(
      { error: 'SUPABASE_SERVICE_ROLE_KEY belum dikonfigurasi di .env.local' },
      { status: 503 }
    )
  }

  try {
    const { percentage } = await request.json()
    if (percentage === undefined || percentage === null) {
      return NextResponse.json({ error: 'percentage wajib diisi' }, { status: 400 })
    }

    const { data, error } = await supabase
      .from('commission_settings')
      .insert({ percentage: Number(percentage) })
      .select()

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 })
    }
    return NextResponse.json({ success: true, data })
  } catch (err) {
    return NextResponse.json({ error: err.message }, { status: 500 })
  }
}
