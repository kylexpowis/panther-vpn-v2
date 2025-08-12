//
//  SupabaseManager.swift
//  PantherVPN
//
//  Created by Kyle Powis on 07/08/2025.
//

import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        let supabaseUrl = URL(string: SUPABASE_URL)!
        let supabaseKey = SUPABASE_ANON_KEY


        self.client = SupabaseClient(supabaseURL: supabaseUrl, supabaseKey: supabaseKey)
    }
}
