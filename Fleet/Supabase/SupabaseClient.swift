import Foundation
import Supabase

let supabaseURL = URL(string: "https://seqotjiuflrjjdrdayrc.supabase.co")!
let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNlcW90aml1ZmxyampkcmRheXJjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxNTQ1NjcsImV4cCI6MjA5NDczMDU2N30.ObrXGupUnqpi-QQoCOqAyxghwXZW97xTAqp5FSW2Yo8"

let supabase = SupabaseClient(
    supabaseURL: supabaseURL,
    supabaseKey: supabaseKey
)