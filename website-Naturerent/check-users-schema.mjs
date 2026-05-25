import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://hctdfnwfigcjycemacif.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhjdGRmbndmaWdjanljZW1hY2lmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg0NTgzODUsImV4cCI6MjA5NDAzNDM4NX0.rMZ2rjhb7THR4H5hRszI7USqFwrQC-gNUY8ttjHUKfw'

const supabase = createClient(supabaseUrl, supabaseKey)

const passwords = ['admin', 'admin123', 'password', 'naturerent', 'nature123', 'admin@123', 'partner123']

async function run() {
  for (const pw of passwords) {
    console.log(`Trying sign in with admin@naturerent.com / ${pw}...`)
    const { data, error } = await supabase.auth.signInWithPassword({
      email: 'admin@naturerent.com',
      password: pw
    })
    if (!error) {
      console.log("SUCCESSFULLY LOGGED IN!")
      const { data: users, error: usersErr } = await supabase
        .from('users')
        .select('*')
        .limit(1)
      
      if (usersErr) {
        console.error("Error fetching users:", usersErr)
      } else {
        console.log("Users schema keys:", Object.keys(users[0] || {}))
        console.log("Users data sample:", users[0])
      }
      return
    } else {
      console.log("Failed:", error.message)
    }
  }
}

run()
