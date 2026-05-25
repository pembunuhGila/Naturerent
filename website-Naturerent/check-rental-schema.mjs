import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://hctdfnwfigcjycemacif.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhjdGRmbndmaWdjanljZW1hY2lmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg0NTgzODUsImV4cCI6MjA5NDAzNDM4NX0.rMZ2rjhb7THR4H5hRszI7USqFwrQC-gNUY8ttjHUKfw'

const supabase = createClient(supabaseUrl, supabaseKey)

async function run() {
  const { data, error } = await supabase.auth.signInWithPassword({
    email: 'admin@naturerent.com',
    password: 'admin123'
  })
  if (error) {
    console.error("Login failed:", error.message)
    return
  }

  const { data: rentals, error: err } = await supabase
    .from('rental_profiles')
    .select('*')
    .limit(1)

  if (err) {
    console.error("Error fetching rental_profiles:", err)
  } else {
    console.log("Rental profiles schema keys:", Object.keys(rentals[0] || {}))
    console.log("Rental profiles data sample:", rentals[0])
  }
}

run()
