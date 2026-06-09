import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://hctdfnwfigcjycemacif.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhjdGRmbndmaWdjanljZW1hY2lmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg0NTgzODUsImV4cCI6MjA5NDAzNDM4NX0.rMZ2rjhb7THR4H5hRszI7USqFwrQC-gNUY8ttjHUKfw'

const supabase = createClient(supabaseUrl, supabaseKey)

async function run() {
  console.log("Logging in...")
  const { data, error } = await supabase.auth.signInWithPassword({
    email: 'admin@naturerent.com',
    password: 'admin123'
  })
  if (error) {
    console.error("Login failed:", error.message)
    return
  }

  // Query 1: join users!owner_id with no_wa
  console.log("\nQuerying with users!owner_id(nama_lengkap, no_wa)...")
  const q1 = await supabase
    .from('rental_profiles')
    .select('*, users!owner_id(nama_lengkap, no_wa)')
    .eq('id', 'a753fc5c-3207-4a59-a6a9-dd891dfe3d27')
    .single()
  
  if (q1.error) {
    console.error("Q1 failed:", q1.error.message, q1.error.code, q1.error.details, q1.error.hint)
  } else {
    console.log("Q1 success:", q1.data)
  }

  // Query 2: join users!owner_id with email
  console.log("\nQuerying with users!owner_id(nama_lengkap, email, no_wa)...")
  const q2 = await supabase
    .from('rental_profiles')
    .select('*, users!owner_id(nama_lengkap, email, no_wa)')
    .eq('id', 'a753fc5c-3207-4a59-a6a9-dd891dfe3d27')
    .single()
  
  if (q2.error) {
    console.error("Q2 failed:", q2.error.message, q2.error.code, q2.error.details, q2.error.hint)
  } else {
    console.log("Q2 success:", q2.data)
  }
}

run()
