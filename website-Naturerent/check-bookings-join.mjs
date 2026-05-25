import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://hctdfnwfigcjycemacif.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhjdGRmbndmaWdjanljZW1hY2lmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg0NTgzODUsImV4cCI6MjA5NDAzNDM4NX0.rMZ2rjhb7THR4H5hRszI7USqFwrQC-gNUY8ttjHUKfw'

const supabase = createClient(supabaseUrl, supabaseKey)

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

  console.log("Testing join: bookings with rental_profiles and owners...")
  const { data, error } = await supabase
    .from('bookings')
    .select('*, rental_profiles(id, nama_rental, users!owner_id(id, nama_lengkap, no_wa))')
    .limit(1)

  if (error) {
    console.error("Join failed:", error.message, error.code, error.details, error.hint)
  } else {
    console.log("Join success! Data structure:", JSON.stringify(data, null, 2))
  }
}

run()
