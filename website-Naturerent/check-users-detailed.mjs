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

  // Query 1: select *
  const q1 = await supabase.from('users').select('*').limit(1)
  console.log("Q1 (select *):", q1.error ? { message: q1.error.message, code: q1.error.code, details: q1.error.details, hint: q1.error.hint } : "SUCCESS")

  // Query 2: select id, nama_lengkap, no_wa
  const q2 = await supabase.from('users').select('id, nama_lengkap, no_wa').limit(1)
  console.log("Q2 (select id, nama_lengkap, no_wa):", q2.error ? { message: q2.error.message, code: q2.error.code, details: q2.error.details, hint: q2.error.hint } : "SUCCESS")

  // Query 3: select id, nama_lengkap, email, no_wa
  const q3 = await supabase.from('users').select('id, nama_lengkap, email, no_wa').limit(1)
  console.log("Q3 (select id, nama_lengkap, email, no_wa):", q3.error ? { message: q3.error.message, code: q3.error.code, details: q3.error.details, hint: q3.error.hint } : "SUCCESS")
}

run()
