import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://hctdfnwfigcjycemacif.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhjdGRmbndmaWdjanljZW1hY2lmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODQ1ODM4NSwiZXhwIjoyMDk0MDM0Mzg1fQ.iIkrzvfzOIKEuMIVROLDzHShrHIB7kAJKo5pQRB6kQc'

const supabase = createClient(supabaseUrl, supabaseKey)

async function test() {
  console.log("Fetching all platform_settings...")
  const { data, error } = await supabase
    .from('platform_settings')
    .select('*')
  
  if (error) {
    console.error("Error fetching:", error)
  } else {
    console.log("Success fetching:", data)
  }
}

test()
