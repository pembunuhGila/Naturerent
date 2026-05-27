import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://hctdfnwfigcjycemacif.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhjdGRmbndmaWdjanljZW1hY2lmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg0NTgzODUsImV4cCI6MjA5NDAzNDM4NX0.rMZ2rjhb7THR4H5hRszI7USqFwrQC-gNUY8ttjHUKfw'

const supabase = createClient(supabaseUrl, supabaseKey)

async function run() {
  console.log("Logging in as admin...")
  const { data, error } = await supabase.auth.signInWithPassword({
    email: 'admin@naturerent.com',
    password: 'admin123'
  })
  if (error) {
    console.error("Login failed:", error.message)
    return
  }

  console.log("Fetching table privileges from information_schema...")
  // We can select from information_schema using custom RPC if available,
  // or we can try to query a view. But wait, PostgREST doesn't expose information_schema by default.
  // Wait! Let's see if we can perform a dynamic Postgres query via an RPC function in Supabase.
  // Do they have any custom function in public schema that executes raw SQL or queries metadata?
  // Let's test standard queries first.
  
  // Can we fetch users table row?
  const { data: users, error: uErr } = await supabase.from('users').select('*').limit(1)
  if (uErr) {
    console.error("Users select error:", uErr.message, uErr.code)
  } else {
    console.log("Users select success. RLS works on select!")
  }
}

run()
