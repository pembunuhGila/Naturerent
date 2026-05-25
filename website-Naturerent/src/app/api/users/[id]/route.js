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

// PATCH /api/users/[id] — Update user
export async function PATCH(request, { params }) {
  const { id } = await params
  const supabase = getAdminClient()
  if (!supabase) {
    return NextResponse.json(
      { error: 'SUPABASE_SERVICE_ROLE_KEY belum dikonfigurasi di .env.local' },
      { status: 503 }
    )
  }

  const body = await request.json()
  const { error } = await supabase.from('users').update(body).eq('id', id)

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 })
  }
  return NextResponse.json({ success: true })
}

// DELETE /api/users/[id] — Delete user
export async function DELETE(request, { params }) {
  const { id } = await params
  const supabase = getAdminClient()
  if (!supabase) {
    return NextResponse.json(
      { error: 'SUPABASE_SERVICE_ROLE_KEY belum dikonfigurasi di .env.local' },
      { status: 503 }
    )
  }

  const { error } = await supabase.from('users').delete().eq('id', id)

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 })
  }
  return NextResponse.json({ success: true })
}
