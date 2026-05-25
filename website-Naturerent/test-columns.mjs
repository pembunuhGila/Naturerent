import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://hctdfnwfigcjycemacif.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhjdGRmbndmaWdjanljZW1hY2lmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg0NTgzODUsImV4cCI6MjA5NDAzNDM4NX0.rMZ2rjhb7THR4H5hRszI7USqFwrQC-gNUY8ttjHUKfw'

const supabase = createClient(supabaseUrl, supabaseKey)

async function test() {
  console.log("Querying users table with id, nama_lengkap, no_wa...")
  const { data, error } = await supabase
    .from('users')
    .select('id, nama_lengkap, no_wa')
    .limit(1)
  
  if (error) {
    console.error("Error without email:", error)
  } else {
    console.log("Success without email:", data)
  }

  console.log("\nQuerying users table with id, nama_lengkap, email, no_wa...")
  const { data: data2, error: error2 } = await supabase
    .from('users')
    .select('id, nama_lengkap, email, no_wa')
    .limit(1)
  
  if (error2) {
    console.error("Error with email:", error2)
  } else {
    console.log("Success with email:", data2)
  }
}

test()
