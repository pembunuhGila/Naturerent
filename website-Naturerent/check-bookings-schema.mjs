import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://hctdfnwfigcjycemacif.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhjdGRmbndmaWdjanljZW1hY2lmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg0NTgzODUsImV4cCI6MjA5NDAzNDM4NX0.rMZ2rjhb7THR4H5hRszI7USqFwrQC-gNUY8ttjHUKfw'

const supabase = createClient(supabaseUrl, supabaseKey)

async function testColumn(columnName) {
  const { data, error } = await supabase.from('bookings').select(columnName).limit(1)
  if (error) {
    console.log(`Column '${columnName}': DOES NOT EXIST (Error: ${error.message})`)
  } else {
    console.log(`Column '${columnName}': EXISTS`)
  }
}

async function run() {
  console.log("Logging in...")
  const { data: auth, error: authError } = await supabase.auth.signInWithPassword({
    email: 'admin@naturerent.com',
    password: 'admin123'
  })
  if (authError) {
    console.error("Login failed:", authError.message)
    return
  }

  const columns = [
    'total_bayar', 'nominal', 'subtotal', 'tgl_pinjam', 'tgl_kembali', 
    'tanggal_pinjam', 'tanggal_kembali', 'mulai', 'selesai', 'tgl_mulai', 'tgl_selesai'
  ]

  console.log("Checking columns on 'bookings' table:")
  for (const col of columns) {
    await testColumn(col)
  }
}

run()
