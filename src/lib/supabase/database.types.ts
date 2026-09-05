export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  public: {
    Tables: {
      asset_network_interfaces: {
        Row: {
          address_mode: string
          archived_at: string | null
          archived_by: string | null
          asset_id: string
          created_at: string
          created_by: string | null
          id: string
          interface_name: string | null
          interface_type: string
          ip_address: unknown
          is_primary: boolean
          mac_address: string | null
          raw_ip_text: string | null
          updated_at: string
          updated_by: string | null
          version: number
          vlan: string | null
        }
        Insert: {
          address_mode?: string
          archived_at?: string | null
          archived_by?: string | null
          asset_id: string
          created_at?: string
          created_by?: string | null
          id?: string
          interface_name?: string | null
          interface_type: string
          ip_address?: unknown
          is_primary?: boolean
          mac_address?: string | null
          raw_ip_text?: string | null
          updated_at?: string
          updated_by?: string | null
          version?: number
          vlan?: string | null
        }
        Update: {
          address_mode?: string
          archived_at?: string | null
          archived_by?: string | null
          asset_id?: string
          created_at?: string
          created_by?: string | null
          id?: string
          interface_name?: string | null
          interface_type?: string
          ip_address?: unknown
          is_primary?: boolean
          mac_address?: string | null
          raw_ip_text?: string | null
          updated_at?: string
          updated_by?: string | null
          version?: number
          vlan?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "asset_network_interfaces_archived_by_fkey"
            columns: ["archived_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "asset_network_interfaces_asset_id_fkey"
            columns: ["asset_id"]
            isOneToOne: false
            referencedRelation: "asset_inventory_v"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "asset_network_interfaces_asset_id_fkey"
            columns: ["asset_id"]
            isOneToOne: false
            referencedRelation: "assets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "asset_network_interfaces_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "asset_network_interfaces_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      asset_person_assignments: {
        Row: {
          archived_at: string | null
          archived_by: string | null
          asset_id: string
          assignment_role: string
          created_at: string
          created_by: string | null
          id: string
          person_id: string
          remark: string | null
          updated_at: string
          updated_by: string | null
          valid_from: string
          valid_to: string | null
          version: number
        }
        Insert: {
          archived_at?: string | null
          archived_by?: string | null
          asset_id: string
          assignment_role: string
          created_at?: string
          created_by?: string | null
          id?: string
          person_id: string
          remark?: string | null
          updated_at?: string
          updated_by?: string | null
          valid_from: string
          valid_to?: string | null
          version?: number
        }
        Update: {
          archived_at?: string | null
          archived_by?: string | null
          asset_id?: string
          assignment_role?: string
          created_at?: string
          created_by?: string | null
          id?: string
          person_id?: string
          remark?: string | null
          updated_at?: string
          updated_by?: string | null
          valid_from?: string
          valid_to?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "asset_person_assignments_archived_by_fkey"
            columns: ["archived_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "asset_person_assignments_asset_id_fkey"
            columns: ["asset_id"]
            isOneToOne: false
            referencedRelation: "asset_inventory_v"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "asset_person_assignments_asset_id_fkey"
            columns: ["asset_id"]
            isOneToOne: false
            referencedRelation: "assets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "asset_person_assignments_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "asset_person_assignments_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "asset_person_assignments_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      asset_software_installations: {
        Row: {
          archived_at: string | null
          archived_by: string | null
          asset_id: string
          created_at: string
          created_by: string | null
          id: string
          installation_status: string
          installed_at: string | null
          installed_version: string | null
          license_allocation_id: string | null
          remark: string | null
          removed_at: string | null
          software_product_id: string
          source: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          archived_at?: string | null
          archived_by?: string | null
          asset_id: string
          created_at?: string
          created_by?: string | null
          id?: string
          installation_status?: string
          installed_at?: string | null
          installed_version?: string | null
          license_allocation_id?: string | null
          remark?: string | null
          removed_at?: string | null
          software_product_id: string
          source?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          archived_at?: string | null
          archived_by?: string | null
          asset_id?: string
          created_at?: string
          created_by?: string | null
          id?: string
          installation_status?: string
          installed_at?: string | null
          installed_version?: string | null
          license_allocation_id?: string | null
          remark?: string | null
          removed_at?: string | null
          software_product_id?: string
          source?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "asset_software_installations_allocation_fk"
            columns: ["license_allocation_id"]
            isOneToOne: false
            referencedRelation: "active_allocations_v"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "asset_software_installations_allocation_fk"
            columns: ["license_allocation_id"]
            isOneToOne: false
            referencedRelation: "license_allocations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "asset_software_installations_archived_by_fkey"
            columns: ["archived_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "asset_software_installations_asset_id_fkey"
            columns: ["asset_id"]
            isOneToOne: false
            referencedRelation: "asset_inventory_v"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "asset_software_installations_asset_id_fkey"
            columns: ["asset_id"]
            isOneToOne: false
            referencedRelation: "assets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "asset_software_installations_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "asset_software_installations_software_product_id_fkey"
            columns: ["software_product_id"]
            isOneToOne: false
            referencedRelation: "asset_inventory_v"
            referencedColumns: ["operating_system_product_id"]
          },
          {
            foreignKeyName: "asset_software_installations_software_product_id_fkey"
            columns: ["software_product_id"]
            isOneToOne: false
            referencedRelation: "software_products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "asset_software_installations_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      asset_statuses: {
        Row: {
          archived_at: string | null
          archived_by: string | null
          code: string
          created_at: string
          created_by: string | null
          id: string
          is_active: boolean
          is_operational: boolean
          is_retired: boolean
          name_en: string | null
          name_th: string
          requires_allocation_warning: boolean
          sort_order: number
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          archived_at?: string | null
          archived_by?: string | null
          code: string
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          is_operational?: boolean
          is_retired?: boolean
          name_en?: string | null
          name_th: string
          requires_allocation_warning?: boolean
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          archived_at?: string | null
          archived_by?: string | null
          code?: string
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          is_operational?: boolean
          is_retired?: boolean
          name_en?: string | null
          name_th?: string
          requires_allocation_warning?: boolean
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "asset_statuses_archived_by_fkey"
            columns: ["archived_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "asset_statuses_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "asset_statuses_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      asset_types: {
        Row: {
          archived_at: string | null
          archived_by: string | null
          code: string
          created_at: string
          created_by: string | null
          id: string
          is_active: boolean
          name_en: string | null
          name_th: string
          sort_order: number
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          archived_at?: string | null
          archived_by?: string | null
          code: string
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          name_en?: string | null
          name_th: string
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          archived_at?: string | null
          archived_by?: string | null
          code?: string
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          name_en?: string | null
          name_th?: string
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "asset_types_archived_by_fkey"
            columns: ["archived_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "asset_types_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "asset_types_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      assets: {
        Row: {
          archived_at: string | null
          archived_by: string | null
          asset_code: string | null
          asset_status_id: string
          asset_type_id: string
          computer_name: string | null
          computer_name_duplicate_approved_at: string | null
          computer_name_duplicate_approved_by: string | null
          computer_name_duplicate_reason: string | null
          created_at: string
          created_by: string | null
          department_id: string | null
          id: string
          internet_level_id: string | null
          location_id: string | null
          manufacturer: string | null
          migration_batch_id: string | null
          migration_reference: string | null
          migration_source_row_id: string | null
          model: string | null
          operating_system_product_id: string | null
          purchase_date: string | null
          remark: string | null
          risk_access_level: string | null
          serial_number: string | null
          site_id: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          archived_at?: string | null
          archived_by?: string | null
          asset_code?: string | null
          asset_status_id: string
          asset_type_id: string
          computer_name?: string | null
          computer_name_duplicate_approved_at?: string | null
          computer_name_duplicate_approved_by?: string | null
          computer_name_duplicate_reason?: string | null
          created_at?: string
          created_by?: string | null
          department_id?: string | null
          id?: string
          internet_level_id?: string | null
          location_id?: string | null
          manufacturer?: string | null
          migration_batch_id?: string | null
          migration_reference?: string | null
          migration_source_row_id?: string | null
          model?: string | null
          operating_system_product_id?: string | null
          purchase_date?: string | null
          remark?: string | null
          risk_access_level?: string | null
          serial_number?: string | null
          site_id: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          archived_at?: string | null
          archived_by?: string | null
          asset_code?: string | null
          asset_status_id?: string
          asset_type_id?: string
          computer_name?: string | null
          computer_name_duplicate_approved_at?: string | null
          computer_name_duplicate_approved_by?: string | null
          computer_name_duplicate_reason?: string | null
          created_at?: string
          created_by?: string | null
          department_id?: string | null
          id?: string
          internet_level_id?: string | null
          location_id?: string | null
          manufacturer?: string | null
          migration_batch_id?: string | null
          migration_reference?: string | null
          migration_source_row_id?: string | null
          model?: string | null
          operating_system_product_id?: string | null
          purchase_date?: string | null
          remark?: string | null
          risk_access_level?: string | null
          serial_number?: string | null
          site_id?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "assets_archived_by_fkey"
            columns: ["archived_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "assets_asset_status_id_fkey"
            columns: ["asset_status_id"]
            isOneToOne: false
            referencedRelation: "asset_statuses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "assets_asset_type_id_fkey"
            columns: ["asset_type_id"]
            isOneToOne: false
            referencedRelation: "asset_types"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "assets_computer_name_duplicate_approved_by_fkey"
            columns: ["computer_name_duplicate_approved_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "assets_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "assets_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "asset_inventory_v"
            referencedColumns: ["department_id"]
          },
          {
            foreignKeyName: "assets_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "assets_internet_level_id_fkey"
            columns: ["internet_level_id"]
            isOneToOne: false
            referencedRelation: "internet_levels"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "assets_location_id_fkey"
            columns: ["location_id"]
            isOneToOne: false
            referencedRelation: "asset_inventory_v"
            referencedColumns: ["location_id"]
          },
          {
            foreignKeyName: "assets_location_id_fkey"
            columns: ["location_id"]
            isOneToOne: false
            referencedRelation: "locations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "assets_operating_system_product_id_fkey"
            columns: ["operating_system_product_id"]
            isOneToOne: false
            referencedRelation: "asset_inventory_v"
            referencedColumns: ["operating_system_product_id"]
          },
          {
            foreignKeyName: "assets_operating_system_product_id_fkey"
            columns: ["operating_system_product_id"]
            isOneToOne: false
            referencedRelation: "software_products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "assets_site_id_fkey"
            columns: ["site_id"]
            isOneToOne: false
            referencedRelation: "asset_inventory_v"
            referencedColumns: ["site_id"]
          },
          {
            foreignKeyName: "assets_site_id_fkey"
            columns: ["site_id"]
            isOneToOne: false
            referencedRelation: "sites"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "assets_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      departments: {
        Row: {
          archived_at: string | null
          archived_by: string | null
          code: string
          created_at: string
          created_by: string | null
          id: string
          is_active: boolean
          name: string
          name_en: string | null
          name_th: string | null
          parent_department_id: string | null
          sort_order: number
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          archived_at?: string | null
          archived_by?: string | null
          code: string
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          name: string
          name_en?: string | null
          name_th?: string | null
          parent_department_id?: string | null
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          archived_at?: string | null
          archived_by?: string | null
          code?: string
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          name?: string
          name_en?: string | null
          name_th?: string | null
          parent_department_id?: string | null
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "departments_archived_by_fkey"
            columns: ["archived_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "departments_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "departments_parent_department_id_fkey"
            columns: ["parent_department_id"]
            isOneToOne: false
            referencedRelation: "asset_inventory_v"
            referencedColumns: ["department_id"]
          },
          {
            foreignKeyName: "departments_parent_department_id_fkey"
            columns: ["parent_department_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "departments_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      expiration_thresholds: {
        Row: {
          archived_at: string | null
          archived_by: string | null
          created_at: string
          created_by: string | null
          days_before_expiry: number
          id: string
          is_active: boolean
          severity: string
          sort_order: number
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          archived_at?: string | null
          archived_by?: string | null
          created_at?: string
          created_by?: string | null
          days_before_expiry: number
          id?: string
          is_active?: boolean
          severity: string
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          archived_at?: string | null
          archived_by?: string | null
          created_at?: string
          created_by?: string | null
          days_before_expiry?: number
          id?: string
          is_active?: boolean
          severity?: string
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "expiration_thresholds_archived_by_fkey"
            columns: ["archived_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "expiration_thresholds_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "expiration_thresholds_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      internet_levels: {
        Row: {
          archived_at: string | null
          archived_by: string | null
          code: string
          created_at: string
          created_by: string | null
          description: string | null
          id: string
          is_active: boolean
          name_en: string | null
          name_th: string
          risk_level: number
          sort_order: number
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          archived_at?: string | null
          archived_by?: string | null
          code: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          is_active?: boolean
          name_en?: string | null
          name_th: string
          risk_level?: number
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          archived_at?: string | null
          archived_by?: string | null
          code?: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          is_active?: boolean
          name_en?: string | null
          name_th?: string
          risk_level?: number
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "internet_levels_archived_by_fkey"
            columns: ["archived_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "internet_levels_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "internet_levels_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      license_allocations: {
        Row: {
          allocated_at: string
          allocation_status: Database["public"]["Enums"]["allocation_status"]
          asset_id: string | null
          created_at: string
          created_by: string | null
          id: string
          installed_at: string | null
          license_entitlement_id: string
          override_reason: string | null
          override_used: boolean
          person_id: string | null
          quantity: number
          release_reason: string | null
          released_at: string | null
          released_by: string | null
          remark: string | null
          site_id: string | null
          target_type: Database["public"]["Enums"]["allocation_target_type"]
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          allocated_at?: string
          allocation_status?: Database["public"]["Enums"]["allocation_status"]
          asset_id?: string | null
          created_at?: string
          created_by?: string | null
          id?: string
          installed_at?: string | null
          license_entitlement_id: string
          override_reason?: string | null
          override_used?: boolean
          person_id?: string | null
          quantity?: number
          release_reason?: string | null
          released_at?: string | null
          released_by?: string | null
          remark?: string | null
          site_id?: string | null
          target_type: Database["public"]["Enums"]["allocation_target_type"]
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          allocated_at?: string
          allocation_status?: Database["public"]["Enums"]["allocation_status"]
          asset_id?: string | null
          created_at?: string
          created_by?: string | null
          id?: string
          installed_at?: string | null
          license_entitlement_id?: string
          override_reason?: string | null
          override_used?: boolean
          person_id?: string | null
          quantity?: number
          release_reason?: string | null
          released_at?: string | null
          released_by?: string | null
          remark?: string | null
          site_id?: string | null
          target_type?: Database["public"]["Enums"]["allocation_target_type"]
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "license_allocations_asset_id_fkey"
            columns: ["asset_id"]
            isOneToOne: false
            referencedRelation: "asset_inventory_v"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_allocations_asset_id_fkey"
            columns: ["asset_id"]
            isOneToOne: false
            referencedRelation: "assets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_allocations_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_allocations_license_entitlement_id_fkey"
            columns: ["license_entitlement_id"]
            isOneToOne: false
            referencedRelation: "license_compliance_v"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_allocations_license_entitlement_id_fkey"
            columns: ["license_entitlement_id"]
            isOneToOne: false
            referencedRelation: "license_entitlements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_allocations_license_entitlement_id_fkey"
            columns: ["license_entitlement_id"]
            isOneToOne: false
            referencedRelation: "license_expiry_v"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_allocations_license_entitlement_id_fkey"
            columns: ["license_entitlement_id"]
            isOneToOne: false
            referencedRelation: "license_safe_v"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_allocations_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_allocations_released_by_fkey"
            columns: ["released_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_allocations_site_id_fkey"
            columns: ["site_id"]
            isOneToOne: false
            referencedRelation: "asset_inventory_v"
            referencedColumns: ["site_id"]
          },
          {
            foreignKeyName: "license_allocations_site_id_fkey"
            columns: ["site_id"]
            isOneToOne: false
            referencedRelation: "sites"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_allocations_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      license_entitlements: {
        Row: {
          archived_at: string | null
          archived_by: string | null
          contract_reference: string | null
          created_at: string
          created_by: string | null
          end_date: string | null
          id: string
          invoice_reference: string | null
          legacy_install_date: string | null
          license_key_masked: string | null
          license_metric_id: string
          license_reference: string | null
          migration_batch_id: string | null
          migration_source_row_id: string | null
          owned_quantity: number | null
          owner_name: string | null
          owner_person_id: string | null
          po_reference: string | null
          product_classification_id: string | null
          purchase_date: string | null
          purchase_form_id: string | null
          record_status: Database["public"]["Enums"]["license_record_status"]
          remark: string | null
          scope_mode: Database["public"]["Enums"]["license_scope_mode"]
          serial_number_masked: string | null
          software_product_id: string
          start_date: string | null
          updated_at: string
          updated_by: string | null
          vendor_id: string | null
          version: number
        }
        Insert: {
          archived_at?: string | null
          archived_by?: string | null
          contract_reference?: string | null
          created_at?: string
          created_by?: string | null
          end_date?: string | null
          id?: string
          invoice_reference?: string | null
          legacy_install_date?: string | null
          license_key_masked?: string | null
          license_metric_id: string
          license_reference?: string | null
          migration_batch_id?: string | null
          migration_source_row_id?: string | null
          owned_quantity?: number | null
          owner_name?: string | null
          owner_person_id?: string | null
          po_reference?: string | null
          product_classification_id?: string | null
          purchase_date?: string | null
          purchase_form_id?: string | null
          record_status?: Database["public"]["Enums"]["license_record_status"]
          remark?: string | null
          scope_mode?: Database["public"]["Enums"]["license_scope_mode"]
          serial_number_masked?: string | null
          software_product_id: string
          start_date?: string | null
          updated_at?: string
          updated_by?: string | null
          vendor_id?: string | null
          version?: number
        }
        Update: {
          archived_at?: string | null
          archived_by?: string | null
          contract_reference?: string | null
          created_at?: string
          created_by?: string | null
          end_date?: string | null
          id?: string
          invoice_reference?: string | null
          legacy_install_date?: string | null
          license_key_masked?: string | null
          license_metric_id?: string
          license_reference?: string | null
          migration_batch_id?: string | null
          migration_source_row_id?: string | null
          owned_quantity?: number | null
          owner_name?: string | null
          owner_person_id?: string | null
          po_reference?: string | null
          product_classification_id?: string | null
          purchase_date?: string | null
          purchase_form_id?: string | null
          record_status?: Database["public"]["Enums"]["license_record_status"]
          remark?: string | null
          scope_mode?: Database["public"]["Enums"]["license_scope_mode"]
          serial_number_masked?: string | null
          software_product_id?: string
          start_date?: string | null
          updated_at?: string
          updated_by?: string | null
          vendor_id?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "license_entitlements_archived_by_fkey"
            columns: ["archived_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_entitlements_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_entitlements_license_metric_id_fkey"
            columns: ["license_metric_id"]
            isOneToOne: false
            referencedRelation: "license_metrics"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_entitlements_owner_person_id_fkey"
            columns: ["owner_person_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_entitlements_product_classification_id_fkey"
            columns: ["product_classification_id"]
            isOneToOne: false
            referencedRelation: "product_classifications"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_entitlements_purchase_form_id_fkey"
            columns: ["purchase_form_id"]
            isOneToOne: false
            referencedRelation: "purchase_forms"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_entitlements_software_product_id_fkey"
            columns: ["software_product_id"]
            isOneToOne: false
            referencedRelation: "asset_inventory_v"
            referencedColumns: ["operating_system_product_id"]
          },
          {
            foreignKeyName: "license_entitlements_software_product_id_fkey"
            columns: ["software_product_id"]
            isOneToOne: false
            referencedRelation: "software_products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_entitlements_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_entitlements_vendor_id_fkey"
            columns: ["vendor_id"]
            isOneToOne: false
            referencedRelation: "vendors"
            referencedColumns: ["id"]
          },
        ]
      }
      license_metrics: {
        Row: {
          allows_multi_seat_allocation: boolean
          archived_at: string | null
          archived_by: string | null
          code: string
          created_at: string
          created_by: string | null
          id: string
          is_active: boolean
          is_perpetual: boolean
          name_en: string | null
          name_th: string
          sort_order: number
          target_mode: Database["public"]["Enums"]["license_target_mode"]
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          allows_multi_seat_allocation?: boolean
          archived_at?: string | null
          archived_by?: string | null
          code: string
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          is_perpetual?: boolean
          name_en?: string | null
          name_th: string
          sort_order?: number
          target_mode: Database["public"]["Enums"]["license_target_mode"]
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          allows_multi_seat_allocation?: boolean
          archived_at?: string | null
          archived_by?: string | null
          code?: string
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          is_perpetual?: boolean
          name_en?: string | null
          name_th?: string
          sort_order?: number
          target_mode?: Database["public"]["Enums"]["license_target_mode"]
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "license_metrics_archived_by_fkey"
            columns: ["archived_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_metrics_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_metrics_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      license_site_scopes: {
        Row: {
          created_at: string
          created_by: string | null
          license_entitlement_id: string
          site_id: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          license_entitlement_id: string
          site_id: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          license_entitlement_id?: string
          site_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "license_site_scopes_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_site_scopes_license_entitlement_id_fkey"
            columns: ["license_entitlement_id"]
            isOneToOne: false
            referencedRelation: "license_compliance_v"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_site_scopes_license_entitlement_id_fkey"
            columns: ["license_entitlement_id"]
            isOneToOne: false
            referencedRelation: "license_entitlements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_site_scopes_license_entitlement_id_fkey"
            columns: ["license_entitlement_id"]
            isOneToOne: false
            referencedRelation: "license_expiry_v"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_site_scopes_license_entitlement_id_fkey"
            columns: ["license_entitlement_id"]
            isOneToOne: false
            referencedRelation: "license_safe_v"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_site_scopes_site_id_fkey"
            columns: ["site_id"]
            isOneToOne: false
            referencedRelation: "asset_inventory_v"
            referencedColumns: ["site_id"]
          },
          {
            foreignKeyName: "license_site_scopes_site_id_fkey"
            columns: ["site_id"]
            isOneToOne: false
            referencedRelation: "sites"
            referencedColumns: ["id"]
          },
        ]
      }
      locations: {
        Row: {
          archived_at: string | null
          archived_by: string | null
          code: string
          created_at: string
          created_by: string | null
          description: string | null
          id: string
          is_active: boolean
          name: string
          site_id: string
          sort_order: number
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          archived_at?: string | null
          archived_by?: string | null
          code: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          is_active?: boolean
          name: string
          site_id: string
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          archived_at?: string | null
          archived_by?: string | null
          code?: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          is_active?: boolean
          name?: string
          site_id?: string
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "locations_archived_by_fkey"
            columns: ["archived_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "locations_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "locations_site_id_fkey"
            columns: ["site_id"]
            isOneToOne: false
            referencedRelation: "asset_inventory_v"
            referencedColumns: ["site_id"]
          },
          {
            foreignKeyName: "locations_site_id_fkey"
            columns: ["site_id"]
            isOneToOne: false
            referencedRelation: "sites"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "locations_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      notification_recipients: {
        Row: {
          delivered_at: string | null
          dismissed_at: string | null
          id: string
          is_dismissed: boolean
          is_read: boolean
          notification_id: string
          profile_id: string
          read_at: string | null
        }
        Insert: {
          delivered_at?: string | null
          dismissed_at?: string | null
          id?: string
          is_dismissed?: boolean
          is_read?: boolean
          notification_id: string
          profile_id: string
          read_at?: string | null
        }
        Update: {
          delivered_at?: string | null
          dismissed_at?: string | null
          id?: string
          is_dismissed?: boolean
          is_read?: boolean
          notification_id?: string
          profile_id?: string
          read_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "notification_recipients_notification_id_fkey"
            columns: ["notification_id"]
            isOneToOne: false
            referencedRelation: "notification_feed_v"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notification_recipients_notification_id_fkey"
            columns: ["notification_id"]
            isOneToOne: false
            referencedRelation: "notifications"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notification_recipients_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          asset_id: string | null
          created_at: string
          deduplication_key: string
          event_date: string
          id: string
          license_allocation_id: string | null
          license_entitlement_id: string | null
          message: string
          notification_type: string
          resolved_at: string | null
          severity: string
          title: string
        }
        Insert: {
          asset_id?: string | null
          created_at?: string
          deduplication_key: string
          event_date: string
          id?: string
          license_allocation_id?: string | null
          license_entitlement_id?: string | null
          message: string
          notification_type: string
          resolved_at?: string | null
          severity: string
          title: string
        }
        Update: {
          asset_id?: string | null
          created_at?: string
          deduplication_key?: string
          event_date?: string
          id?: string
          license_allocation_id?: string | null
          license_entitlement_id?: string | null
          message?: string
          notification_type?: string
          resolved_at?: string | null
          severity?: string
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "notifications_asset_id_fkey"
            columns: ["asset_id"]
            isOneToOne: false
            referencedRelation: "asset_inventory_v"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_asset_id_fkey"
            columns: ["asset_id"]
            isOneToOne: false
            referencedRelation: "assets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_license_allocation_id_fkey"
            columns: ["license_allocation_id"]
            isOneToOne: false
            referencedRelation: "active_allocations_v"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_license_allocation_id_fkey"
            columns: ["license_allocation_id"]
            isOneToOne: false
            referencedRelation: "license_allocations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_license_entitlement_id_fkey"
            columns: ["license_entitlement_id"]
            isOneToOne: false
            referencedRelation: "license_compliance_v"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_license_entitlement_id_fkey"
            columns: ["license_entitlement_id"]
            isOneToOne: false
            referencedRelation: "license_entitlements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_license_entitlement_id_fkey"
            columns: ["license_entitlement_id"]
            isOneToOne: false
            referencedRelation: "license_expiry_v"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_license_entitlement_id_fkey"
            columns: ["license_entitlement_id"]
            isOneToOne: false
            referencedRelation: "license_safe_v"
            referencedColumns: ["id"]
          },
        ]
      }
      people: {
        Row: {
          archived_at: string | null
          archived_by: string | null
          created_at: string
          created_by: string | null
          department_id: string | null
          display_name: string
          email: string | null
          employee_code: string | null
          employment_status: string
          id: string
          primary_site_id: string | null
          remark: string | null
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          archived_at?: string | null
          archived_by?: string | null
          created_at?: string
          created_by?: string | null
          department_id?: string | null
          display_name: string
          email?: string | null
          employee_code?: string | null
          employment_status?: string
          id?: string
          primary_site_id?: string | null
          remark?: string | null
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          archived_at?: string | null
          archived_by?: string | null
          created_at?: string
          created_by?: string | null
          department_id?: string | null
          display_name?: string
          email?: string | null
          employee_code?: string | null
          employment_status?: string
          id?: string
          primary_site_id?: string | null
          remark?: string | null
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "people_archived_by_fkey"
            columns: ["archived_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "people_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "people_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "asset_inventory_v"
            referencedColumns: ["department_id"]
          },
          {
            foreignKeyName: "people_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "people_primary_site_id_fkey"
            columns: ["primary_site_id"]
            isOneToOne: false
            referencedRelation: "asset_inventory_v"
            referencedColumns: ["site_id"]
          },
          {
            foreignKeyName: "people_primary_site_id_fkey"
            columns: ["primary_site_id"]
            isOneToOne: false
            referencedRelation: "sites"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "people_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      product_classifications: {
        Row: {
          archived_at: string | null
          archived_by: string | null
          code: string
          created_at: string
          created_by: string | null
          id: string
          is_active: boolean
          name_en: string | null
          name_th: string
          sort_order: number
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          archived_at?: string | null
          archived_by?: string | null
          code: string
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          name_en?: string | null
          name_th: string
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          archived_at?: string | null
          archived_by?: string | null
          code?: string
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          name_en?: string | null
          name_th?: string
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "product_classifications_archived_by_fkey"
            columns: ["archived_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_classifications_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_classifications_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          account_status: Database["public"]["Enums"]["account_status"]
          app_role: Database["public"]["Enums"]["app_role"]
          created_at: string
          created_by: string | null
          deactivated_at: string | null
          deactivated_by: string | null
          display_name: string
          email: string
          failed_login_count: number
          id: string
          last_login_at: string | null
          locked_until: string | null
          person_id: string | null
          updated_at: string
          updated_by: string | null
          username: string | null
          version: number
        }
        Insert: {
          account_status?: Database["public"]["Enums"]["account_status"]
          app_role?: Database["public"]["Enums"]["app_role"]
          created_at?: string
          created_by?: string | null
          deactivated_at?: string | null
          deactivated_by?: string | null
          display_name: string
          email: string
          failed_login_count?: number
          id: string
          last_login_at?: string | null
          locked_until?: string | null
          person_id?: string | null
          updated_at?: string
          updated_by?: string | null
          username?: string | null
          version?: number
        }
        Update: {
          account_status?: Database["public"]["Enums"]["account_status"]
          app_role?: Database["public"]["Enums"]["app_role"]
          created_at?: string
          created_by?: string | null
          deactivated_at?: string | null
          deactivated_by?: string | null
          display_name?: string
          email?: string
          failed_login_count?: number
          id?: string
          last_login_at?: string | null
          locked_until?: string | null
          person_id?: string | null
          updated_at?: string
          updated_by?: string | null
          username?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "profiles_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "profiles_deactivated_by_fkey"
            columns: ["deactivated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "profiles_person_id_fk"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "profiles_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      publishers: {
        Row: {
          archived_at: string | null
          archived_by: string | null
          code: string
          created_at: string
          created_by: string | null
          id: string
          is_active: boolean
          name_en: string | null
          name_th: string
          sort_order: number
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          archived_at?: string | null
          archived_by?: string | null
          code: string
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          name_en?: string | null
          name_th: string
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          archived_at?: string | null
          archived_by?: string | null
          code?: string
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          name_en?: string | null
          name_th?: string
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "publishers_archived_by_fkey"
            columns: ["archived_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "publishers_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "publishers_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      purchase_forms: {
        Row: {
          archived_at: string | null
          archived_by: string | null
          code: string
          created_at: string
          created_by: string | null
          id: string
          is_active: boolean
          name_en: string | null
          name_th: string
          sort_order: number
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          archived_at?: string | null
          archived_by?: string | null
          code: string
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          name_en?: string | null
          name_th: string
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          archived_at?: string | null
          archived_by?: string | null
          code?: string
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          name_en?: string | null
          name_th?: string
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "purchase_forms_archived_by_fkey"
            columns: ["archived_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchase_forms_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchase_forms_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      sites: {
        Row: {
          archived_at: string | null
          archived_by: string | null
          code: string
          created_at: string
          created_by: string | null
          id: string
          is_active: boolean
          name_en: string | null
          name_th: string
          sort_order: number
          timezone: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          archived_at?: string | null
          archived_by?: string | null
          code: string
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          name_en?: string | null
          name_th: string
          sort_order?: number
          timezone?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          archived_at?: string | null
          archived_by?: string | null
          code?: string
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          name_en?: string | null
          name_th?: string
          sort_order?: number
          timezone?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "sites_archived_by_fkey"
            columns: ["archived_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sites_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sites_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      software_categories: {
        Row: {
          archived_at: string | null
          archived_by: string | null
          code: string
          created_at: string
          created_by: string | null
          id: string
          is_active: boolean
          name_en: string | null
          name_th: string
          sort_order: number
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          archived_at?: string | null
          archived_by?: string | null
          code: string
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          name_en?: string | null
          name_th: string
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          archived_at?: string | null
          archived_by?: string | null
          code?: string
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          name_en?: string | null
          name_th?: string
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "software_categories_archived_by_fkey"
            columns: ["archived_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "software_categories_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "software_categories_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      software_products: {
        Row: {
          archived_at: string | null
          archived_by: string | null
          category_id: string
          created_at: string
          created_by: string | null
          end_of_life_date: string | null
          id: string
          name: string
          publisher_id: string
          remark: string | null
          support_status: string
          updated_at: string
          updated_by: string | null
          version: number
          version_edition: string
        }
        Insert: {
          archived_at?: string | null
          archived_by?: string | null
          category_id: string
          created_at?: string
          created_by?: string | null
          end_of_life_date?: string | null
          id?: string
          name: string
          publisher_id: string
          remark?: string | null
          support_status?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
          version_edition?: string
        }
        Update: {
          archived_at?: string | null
          archived_by?: string | null
          category_id?: string
          created_at?: string
          created_by?: string | null
          end_of_life_date?: string | null
          id?: string
          name?: string
          publisher_id?: string
          remark?: string | null
          support_status?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
          version_edition?: string
        }
        Relationships: [
          {
            foreignKeyName: "software_products_archived_by_fkey"
            columns: ["archived_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "software_products_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "software_categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "software_products_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "software_products_publisher_id_fkey"
            columns: ["publisher_id"]
            isOneToOne: false
            referencedRelation: "publishers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "software_products_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      system_settings: {
        Row: {
          audit_retention_months: number
          created_at: string
          created_by: string | null
          date_format: string
          default_page_size: number
          id: number
          max_login_failures: number
          organization_name: string
          over_allocation_policy: string
          secret_visible_suffix_length: number
          session_timeout_minutes: number
          timezone: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          audit_retention_months?: number
          created_at?: string
          created_by?: string | null
          date_format?: string
          default_page_size?: number
          id?: number
          max_login_failures?: number
          organization_name?: string
          over_allocation_policy?: string
          secret_visible_suffix_length?: number
          session_timeout_minutes?: number
          timezone?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          audit_retention_months?: number
          created_at?: string
          created_by?: string | null
          date_format?: string
          default_page_size?: number
          id?: number
          max_login_failures?: number
          organization_name?: string
          over_allocation_policy?: string
          secret_visible_suffix_length?: number
          session_timeout_minutes?: number
          timezone?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "system_settings_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "system_settings_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      vendors: {
        Row: {
          archived_at: string | null
          archived_by: string | null
          code: string
          contact_name: string | null
          created_at: string
          created_by: string | null
          email: string | null
          id: string
          is_active: boolean
          name_en: string | null
          name_th: string
          phone: string | null
          remark: string | null
          sort_order: number
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          archived_at?: string | null
          archived_by?: string | null
          code: string
          contact_name?: string | null
          created_at?: string
          created_by?: string | null
          email?: string | null
          id?: string
          is_active?: boolean
          name_en?: string | null
          name_th: string
          phone?: string | null
          remark?: string | null
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          archived_at?: string | null
          archived_by?: string | null
          code?: string
          contact_name?: string | null
          created_at?: string
          created_by?: string | null
          email?: string | null
          id?: string
          is_active?: boolean
          name_en?: string | null
          name_th?: string
          phone?: string | null
          remark?: string | null
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "vendors_archived_by_fkey"
            columns: ["archived_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vendors_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vendors_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      active_allocations_v: {
        Row: {
          allocated_at: string | null
          asset_id: string | null
          id: string | null
          installed_at: string | null
          license_entitlement_id: string | null
          override_reason: string | null
          override_used: boolean | null
          person_id: string | null
          quantity: number | null
          remark: string | null
          site_id: string | null
          target_display_name: string | null
          target_type:
            | Database["public"]["Enums"]["allocation_target_type"]
            | null
        }
        Relationships: [
          {
            foreignKeyName: "license_allocations_asset_id_fkey"
            columns: ["asset_id"]
            isOneToOne: false
            referencedRelation: "asset_inventory_v"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_allocations_asset_id_fkey"
            columns: ["asset_id"]
            isOneToOne: false
            referencedRelation: "assets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_allocations_license_entitlement_id_fkey"
            columns: ["license_entitlement_id"]
            isOneToOne: false
            referencedRelation: "license_compliance_v"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_allocations_license_entitlement_id_fkey"
            columns: ["license_entitlement_id"]
            isOneToOne: false
            referencedRelation: "license_entitlements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_allocations_license_entitlement_id_fkey"
            columns: ["license_entitlement_id"]
            isOneToOne: false
            referencedRelation: "license_expiry_v"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_allocations_license_entitlement_id_fkey"
            columns: ["license_entitlement_id"]
            isOneToOne: false
            referencedRelation: "license_safe_v"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_allocations_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_allocations_site_id_fkey"
            columns: ["site_id"]
            isOneToOne: false
            referencedRelation: "asset_inventory_v"
            referencedColumns: ["site_id"]
          },
          {
            foreignKeyName: "license_allocations_site_id_fkey"
            columns: ["site_id"]
            isOneToOne: false
            referencedRelation: "sites"
            referencedColumns: ["id"]
          },
        ]
      }
      asset_current_people_v: {
        Row: {
          asset_id: string | null
          primary_user_name: string | null
          responsible_person_name: string | null
        }
        Relationships: [
          {
            foreignKeyName: "asset_person_assignments_asset_id_fkey"
            columns: ["asset_id"]
            isOneToOne: false
            referencedRelation: "asset_inventory_v"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "asset_person_assignments_asset_id_fkey"
            columns: ["asset_id"]
            isOneToOne: false
            referencedRelation: "assets"
            referencedColumns: ["id"]
          },
        ]
      }
      asset_inventory_v: {
        Row: {
          archived_at: string | null
          asset_code: string | null
          asset_status_code: string | null
          asset_type_code: string | null
          computer_name: string | null
          department_id: string | null
          department_name: string | null
          id: string | null
          location_id: string | null
          location_name: string | null
          manufacturer: string | null
          model: string | null
          operating_system_name: string | null
          operating_system_product_id: string | null
          operating_system_version: string | null
          primary_user_name: string | null
          purchase_date: string | null
          remark: string | null
          responsible_person_name: string | null
          risk_access_level: string | null
          serial_number: string | null
          site_code: string | null
          site_id: string | null
          site_name: string | null
          version: number | null
        }
        Relationships: []
      }
      audit_log_admin_v: {
        Row: {
          action: string | null
          actor_profile_id: string | null
          actor_type: string | null
          correlation_id: string | null
          description: string | null
          entity_id: string | null
          entity_type: string | null
          id: string | null
          metadata: Json | null
          new_values: Json | null
          occurred_at: string | null
          old_values: Json | null
          reason: string | null
        }
        Insert: {
          action?: string | null
          actor_profile_id?: string | null
          actor_type?: string | null
          correlation_id?: string | null
          description?: string | null
          entity_id?: string | null
          entity_type?: string | null
          id?: string | null
          metadata?: Json | null
          new_values?: Json | null
          occurred_at?: string | null
          old_values?: Json | null
          reason?: string | null
        }
        Update: {
          action?: string | null
          actor_profile_id?: string | null
          actor_type?: string | null
          correlation_id?: string | null
          description?: string | null
          entity_id?: string | null
          entity_type?: string | null
          id?: string | null
          metadata?: Json | null
          new_values?: Json | null
          occurred_at?: string | null
          old_values?: Json | null
          reason?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "audit_events_actor_profile_id_fkey"
            columns: ["actor_profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      dashboard_summary_v: {
        Row: {
          active_asset_count: number | null
          allocated_quantity: number | null
          expired_count: number | null
          license_count: number | null
          over_allocated_count: number | null
          owned_quantity: number | null
        }
        Relationships: []
      }
      data_quality_v: {
        Row: {
          description: string | null
          entity_id: string | null
          entity_type: string | null
          issue_code: string | null
        }
        Relationships: []
      }
      license_compliance_v: {
        Row: {
          allocated_quantity: number | null
          available_quantity: number | null
          compliance_status: string | null
          id: string | null
          license_reference: string | null
          owned_quantity: number | null
          software_product_id: string | null
        }
        Relationships: [
          {
            foreignKeyName: "license_entitlements_software_product_id_fkey"
            columns: ["software_product_id"]
            isOneToOne: false
            referencedRelation: "asset_inventory_v"
            referencedColumns: ["operating_system_product_id"]
          },
          {
            foreignKeyName: "license_entitlements_software_product_id_fkey"
            columns: ["software_product_id"]
            isOneToOne: false
            referencedRelation: "software_products"
            referencedColumns: ["id"]
          },
        ]
      }
      license_expiry_v: {
        Row: {
          days_remaining: number | null
          end_date: string | null
          id: string | null
          lifecycle_status: string | null
          start_date: string | null
          threshold_days: number | null
        }
        Relationships: []
      }
      license_safe_v: {
        Row: {
          allocated_quantity: number | null
          archived_at: string | null
          available_quantity: number | null
          compliance_status: string | null
          days_remaining: number | null
          end_date: string | null
          id: string | null
          license_key_masked: string | null
          license_metric_id: string | null
          license_reference: string | null
          lifecycle_status: string | null
          owned_quantity: number | null
          product_name: string | null
          publisher_name: string | null
          purchase_date: string | null
          record_status:
            | Database["public"]["Enums"]["license_record_status"]
            | null
          remark: string | null
          scope_mode: Database["public"]["Enums"]["license_scope_mode"] | null
          serial_number_masked: string | null
          software_product_id: string | null
          start_date: string | null
          vendor_id: string | null
          version: number | null
          version_edition: string | null
        }
        Relationships: [
          {
            foreignKeyName: "license_entitlements_license_metric_id_fkey"
            columns: ["license_metric_id"]
            isOneToOne: false
            referencedRelation: "license_metrics"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_entitlements_software_product_id_fkey"
            columns: ["software_product_id"]
            isOneToOne: false
            referencedRelation: "asset_inventory_v"
            referencedColumns: ["operating_system_product_id"]
          },
          {
            foreignKeyName: "license_entitlements_software_product_id_fkey"
            columns: ["software_product_id"]
            isOneToOne: false
            referencedRelation: "software_products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "license_entitlements_vendor_id_fkey"
            columns: ["vendor_id"]
            isOneToOne: false
            referencedRelation: "vendors"
            referencedColumns: ["id"]
          },
        ]
      }
      notification_feed_v: {
        Row: {
          created_at: string | null
          delivered_at: string | null
          dismissed_at: string | null
          event_date: string | null
          id: string | null
          is_dismissed: boolean | null
          is_read: boolean | null
          message: string | null
          notification_type: string | null
          read_at: string | null
          recipient_id: string | null
          resolved_at: string | null
          severity: string | null
          title: string | null
        }
        Relationships: []
      }
    }
    Functions: {
      acknowledge_import_warnings: {
        Args: { expected_version: number; import_batch_id: string }
        Returns: number
      }
      allocate_license: {
        Args: { payload: Json }
        Returns: {
          allocated_at: string
          allocation_status: Database["public"]["Enums"]["allocation_status"]
          asset_id: string | null
          created_at: string
          created_by: string | null
          id: string
          installed_at: string | null
          license_entitlement_id: string
          override_reason: string | null
          override_used: boolean
          person_id: string | null
          quantity: number
          release_reason: string | null
          released_at: string | null
          released_by: string | null
          remark: string | null
          site_id: string | null
          target_type: Database["public"]["Enums"]["allocation_target_type"]
          updated_at: string
          updated_by: string | null
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "license_allocations"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      archive_asset: {
        Args: {
          acknowledge_allocations: boolean
          asset_id: string
          expected_version: number
          reason: string
        }
        Returns: {
          archived_at: string | null
          archived_by: string | null
          asset_code: string | null
          asset_status_id: string
          asset_type_id: string
          computer_name: string | null
          computer_name_duplicate_approved_at: string | null
          computer_name_duplicate_approved_by: string | null
          computer_name_duplicate_reason: string | null
          created_at: string
          created_by: string | null
          department_id: string | null
          id: string
          internet_level_id: string | null
          location_id: string | null
          manufacturer: string | null
          migration_batch_id: string | null
          migration_reference: string | null
          migration_source_row_id: string | null
          model: string | null
          operating_system_product_id: string | null
          purchase_date: string | null
          remark: string | null
          risk_access_level: string | null
          serial_number: string | null
          site_id: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "assets"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      archive_license_entitlement: {
        Args: {
          entitlement_id: string
          expected_version: number
          reason: string
        }
        Returns: {
          archived_at: string | null
          archived_by: string | null
          contract_reference: string | null
          created_at: string
          created_by: string | null
          end_date: string | null
          id: string
          invoice_reference: string | null
          legacy_install_date: string | null
          license_key_masked: string | null
          license_metric_id: string
          license_reference: string | null
          migration_batch_id: string | null
          migration_source_row_id: string | null
          owned_quantity: number | null
          owner_name: string | null
          owner_person_id: string | null
          po_reference: string | null
          product_classification_id: string | null
          purchase_date: string | null
          purchase_form_id: string | null
          record_status: Database["public"]["Enums"]["license_record_status"]
          remark: string | null
          scope_mode: Database["public"]["Enums"]["license_scope_mode"]
          serial_number_masked: string | null
          software_product_id: string
          start_date: string | null
          updated_at: string
          updated_by: string | null
          vendor_id: string | null
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "license_entitlements"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      archive_master_data: {
        Args: {
          entity_id: string
          entity_type: string
          expected_version: number
          reason: string
        }
        Returns: Json
      }
      archive_software_product: {
        Args: { expected_version: number; product_id: string; reason: string }
        Returns: {
          archived_at: string | null
          archived_by: string | null
          category_id: string
          created_at: string
          created_by: string | null
          end_of_life_date: string | null
          id: string
          name: string
          publisher_id: string
          remark: string | null
          support_status: string
          updated_at: string
          updated_by: string | null
          version: number
          version_edition: string
        }
        SetofOptions: {
          from: "*"
          to: "software_products"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      begin_import_batch: { Args: { payload: Json }; Returns: string }
      create_asset: {
        Args: { payload: Json }
        Returns: {
          archived_at: string | null
          archived_by: string | null
          asset_code: string | null
          asset_status_id: string
          asset_type_id: string
          computer_name: string | null
          computer_name_duplicate_approved_at: string | null
          computer_name_duplicate_approved_by: string | null
          computer_name_duplicate_reason: string | null
          created_at: string
          created_by: string | null
          department_id: string | null
          id: string
          internet_level_id: string | null
          location_id: string | null
          manufacturer: string | null
          migration_batch_id: string | null
          migration_reference: string | null
          migration_source_row_id: string | null
          model: string | null
          operating_system_product_id: string | null
          purchase_date: string | null
          remark: string | null
          risk_access_level: string | null
          serial_number: string | null
          site_id: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "assets"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      create_license_entitlement: {
        Args: { payload: Json; secret_payload: Json }
        Returns: {
          archived_at: string | null
          archived_by: string | null
          contract_reference: string | null
          created_at: string
          created_by: string | null
          end_date: string | null
          id: string
          invoice_reference: string | null
          legacy_install_date: string | null
          license_key_masked: string | null
          license_metric_id: string
          license_reference: string | null
          migration_batch_id: string | null
          migration_source_row_id: string | null
          owned_quantity: number | null
          owner_name: string | null
          owner_person_id: string | null
          po_reference: string | null
          product_classification_id: string | null
          purchase_date: string | null
          purchase_form_id: string | null
          record_status: Database["public"]["Enums"]["license_record_status"]
          remark: string | null
          scope_mode: Database["public"]["Enums"]["license_scope_mode"]
          serial_number_masked: string | null
          software_product_id: string
          start_date: string | null
          updated_at: string
          updated_by: string | null
          vendor_id: string | null
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "license_entitlements"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      create_software_product: {
        Args: { payload: Json }
        Returns: {
          archived_at: string | null
          archived_by: string | null
          category_id: string
          created_at: string
          created_by: string | null
          end_of_life_date: string | null
          id: string
          name: string
          publisher_id: string
          remark: string | null
          support_status: string
          updated_at: string
          updated_by: string | null
          version: number
          version_edition: string
        }
        SetofOptions: {
          from: "*"
          to: "software_products"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      export_report: {
        Args: { filters: Json; report_type: string }
        Returns: Json[]
      }
      get_import_batch_review: {
        Args: { import_batch_id: string }
        Returns: Json
      }
      publish_import_batch: {
        Args: {
          acknowledge_warnings: boolean
          expected_version: number
          import_batch_id: string
        }
        Returns: Database["public"]["CompositeTypes"]["import_publish_summary"]
        SetofOptions: {
          from: "*"
          to: "import_publish_summary"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      release_license_allocation: {
        Args: {
          allocation_id: string
          expected_version: number
          reason: string
        }
        Returns: {
          allocated_at: string
          allocation_status: Database["public"]["Enums"]["allocation_status"]
          asset_id: string | null
          created_at: string
          created_by: string | null
          id: string
          installed_at: string | null
          license_entitlement_id: string
          override_reason: string | null
          override_used: boolean
          person_id: string | null
          quantity: number
          release_reason: string | null
          released_at: string | null
          released_by: string | null
          remark: string | null
          site_id: string | null
          target_type: Database["public"]["Enums"]["allocation_target_type"]
          updated_at: string
          updated_by: string | null
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "license_allocations"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      reveal_license_secret: {
        Args: {
          correlation_id: string
          entitlement_id: string
          secret_type: string
        }
        Returns: Database["public"]["CompositeTypes"]["license_secret_reveal"]
        SetofOptions: {
          from: "*"
          to: "license_secret_reveal"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      rotate_license_secret: {
        Args: {
          entitlement_id: string
          reason: string
          secret_type: string
          value: string
        }
        Returns: {
          archived_at: string | null
          archived_by: string | null
          contract_reference: string | null
          created_at: string
          created_by: string | null
          end_date: string | null
          id: string
          invoice_reference: string | null
          legacy_install_date: string | null
          license_key_masked: string | null
          license_metric_id: string
          license_reference: string | null
          migration_batch_id: string | null
          migration_source_row_id: string | null
          owned_quantity: number | null
          owner_name: string | null
          owner_person_id: string | null
          po_reference: string | null
          product_classification_id: string | null
          purchase_date: string | null
          purchase_form_id: string | null
          record_status: Database["public"]["Enums"]["license_record_status"]
          remark: string | null
          scope_mode: Database["public"]["Enums"]["license_scope_mode"]
          serial_number_masked: string | null
          software_product_id: string
          start_date: string | null
          updated_at: string
          updated_by: string | null
          vendor_id: string | null
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "license_entitlements"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      set_notification_state: {
        Args: { is_dismissed: boolean; is_read: boolean; recipient_id: string }
        Returns: {
          delivered_at: string | null
          dismissed_at: string | null
          id: string
          is_dismissed: boolean
          is_read: boolean
          notification_id: string
          profile_id: string
          read_at: string | null
        }
        SetofOptions: {
          from: "*"
          to: "notification_recipients"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      set_user_role: {
        Args: {
          new_role: Database["public"]["Enums"]["app_role"]
          profile_id: string
          reason: string
        }
        Returns: {
          account_status: Database["public"]["Enums"]["account_status"]
          app_role: Database["public"]["Enums"]["app_role"]
          created_at: string
          created_by: string | null
          deactivated_at: string | null
          deactivated_by: string | null
          display_name: string
          email: string
          failed_login_count: number
          id: string
          last_login_at: string | null
          locked_until: string | null
          person_id: string | null
          updated_at: string
          updated_by: string | null
          username: string | null
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "profiles"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      set_user_status: {
        Args: {
          new_status: Database["public"]["Enums"]["account_status"]
          profile_id: string
          reason: string
        }
        Returns: {
          account_status: Database["public"]["Enums"]["account_status"]
          app_role: Database["public"]["Enums"]["app_role"]
          created_at: string
          created_by: string | null
          deactivated_at: string | null
          deactivated_by: string | null
          display_name: string
          email: string
          failed_login_count: number
          id: string
          last_login_at: string | null
          locked_until: string | null
          person_id: string | null
          updated_at: string
          updated_by: string | null
          username: string | null
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "profiles"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      stage_asset_rows: {
        Args: { import_batch_id: string; rows: Json }
        Returns: number
      }
      stage_license_rows: {
        Args: { import_batch_id: string; rows: Json }
        Returns: number
      }
      update_asset: {
        Args: { asset_id: string; expected_version: number; payload: Json }
        Returns: {
          archived_at: string | null
          archived_by: string | null
          asset_code: string | null
          asset_status_id: string
          asset_type_id: string
          computer_name: string | null
          computer_name_duplicate_approved_at: string | null
          computer_name_duplicate_approved_by: string | null
          computer_name_duplicate_reason: string | null
          created_at: string
          created_by: string | null
          department_id: string | null
          id: string
          internet_level_id: string | null
          location_id: string | null
          manufacturer: string | null
          migration_batch_id: string | null
          migration_reference: string | null
          migration_source_row_id: string | null
          model: string | null
          operating_system_product_id: string | null
          purchase_date: string | null
          remark: string | null
          risk_access_level: string | null
          serial_number: string | null
          site_id: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "assets"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      update_license_entitlement: {
        Args: {
          entitlement_id: string
          expected_version: number
          payload: Json
        }
        Returns: {
          archived_at: string | null
          archived_by: string | null
          contract_reference: string | null
          created_at: string
          created_by: string | null
          end_date: string | null
          id: string
          invoice_reference: string | null
          legacy_install_date: string | null
          license_key_masked: string | null
          license_metric_id: string
          license_reference: string | null
          migration_batch_id: string | null
          migration_source_row_id: string | null
          owned_quantity: number | null
          owner_name: string | null
          owner_person_id: string | null
          po_reference: string | null
          product_classification_id: string | null
          purchase_date: string | null
          purchase_form_id: string | null
          record_status: Database["public"]["Enums"]["license_record_status"]
          remark: string | null
          scope_mode: Database["public"]["Enums"]["license_scope_mode"]
          serial_number_masked: string | null
          software_product_id: string
          start_date: string | null
          updated_at: string
          updated_by: string | null
          vendor_id: string | null
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "license_entitlements"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      update_master_data: {
        Args: {
          entity_id: string
          entity_type: string
          expected_version: number
          payload: Json
        }
        Returns: Json
      }
      update_software_product: {
        Args: { expected_version: number; payload: Json; product_id: string }
        Returns: {
          archived_at: string | null
          archived_by: string | null
          category_id: string
          created_at: string
          created_by: string | null
          end_of_life_date: string | null
          id: string
          name: string
          publisher_id: string
          remark: string | null
          support_status: string
          updated_at: string
          updated_by: string | null
          version: number
          version_edition: string
        }
        SetofOptions: {
          from: "*"
          to: "software_products"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      update_system_settings: {
        Args: { expected_version: number; payload: Json }
        Returns: {
          audit_retention_months: number
          created_at: string
          created_by: string | null
          date_format: string
          default_page_size: number
          id: number
          max_login_failures: number
          organization_name: string
          over_allocation_policy: string
          secret_visible_suffix_length: number
          session_timeout_minutes: number
          timezone: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "system_settings"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      validate_import_batch: {
        Args: { import_batch_id: string }
        Returns: Database["public"]["CompositeTypes"]["import_validation_summary"]
        SetofOptions: {
          from: "*"
          to: "import_validation_summary"
          isOneToOne: true
          isSetofReturn: false
        }
      }
    }
    Enums: {
      account_status: "active" | "inactive" | "locked"
      allocation_status: "active" | "released"
      allocation_target_type: "asset" | "person" | "site"
      app_role: "admin" | "user"
      license_record_status: "draft" | "active" | "deactivated" | "archived"
      license_scope_mode: "all_sites" | "selected_sites"
      license_target_mode:
        | "device"
        | "named_user"
        | "concurrent"
        | "site"
        | "mixed"
    }
    CompositeTypes: {
      import_publish_summary: {
        import_batch_id: string | null
        assets_created: number | null
        products_created: number | null
        licenses_created: number | null
        allocations_created: number | null
        duplicate_rows_skipped: number | null
        warning_rows_skipped: number | null
        audit_event_id: string | null
      }
      import_validation_summary: {
        import_batch_id: string | null
        valid_count: number | null
        warning_count: number | null
        error_count: number | null
        duplicate_count: number | null
        skipped_count: number | null
        version: number | null
      }
      license_secret_reveal: {
        secret_type: string | null
        secret_value: string | null
        correlation_id: string | null
        revealed_at: string | null
      }
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      account_status: ["active", "inactive", "locked"],
      allocation_status: ["active", "released"],
      allocation_target_type: ["asset", "person", "site"],
      app_role: ["admin", "user"],
      license_record_status: ["draft", "active", "deactivated", "archived"],
      license_scope_mode: ["all_sites", "selected_sites"],
      license_target_mode: [
        "device",
        "named_user",
        "concurrent",
        "site",
        "mixed",
      ],
    },
  },
} as const

