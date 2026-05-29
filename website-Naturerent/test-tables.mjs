import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://hctdfnwfigcjycemacif.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhjdGRmbndmaWdjanljZW1hY2lmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODQ1ODM4NSwiZXhwIjoyMDk0MDM0Mzg1fQ.iIkrzvfzOIKEuMIVROLDzHShrHIB7kAJKo5pQRB6kQc'

const supabase = createClient(supabaseUrl, supabaseKey)

const tables = [
  'users',
  'rental_profiles',
  'bookings',
  'commission_settings',
  'platform_settings',
  'wisata_locations'
]

async function test() {
  for (const table of tables) {
    const { data, error } = await supabase.from(table).select('*').limit(1)
    if (error) {
      console.log(`❌ Table ${table} select error: ${error.message} (code: ${error.code})`)
    } else {
      console.log(`✅ Table ${table} select success! Rows: ${data.length}`)
    }
  }
}

test()
