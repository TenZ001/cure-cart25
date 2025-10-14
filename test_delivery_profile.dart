import 'package:flutter/material.dart';
import 'lib/api_service.dart';

void main() async {
  // Test delivery partner profile retrieval for delivery@gmail.com
  print("🔍 Testing delivery partner profile retrieval...");
  
  final apiService = ApiService();
  
  try {
    // Get delivery partner profile
    final profile = await apiService.getDeliveryProfile();
    
    if (profile != null) {
      print("✅ Delivery Partner Profile Found:");
      print("📋 Profile Data:");
      print("   - ID: ${profile['_id']}");
      print("   - Name: ${profile['name']}");
      print("   - Contact: ${profile['contact']}");
      print("   - NIC: ${profile['nic']}");
      print("   - License: ${profile['licenseNumber']}");
      print("   - Vehicle: ${profile['vehicleNo']}");
      print("   - Status: ${profile['status']}");
      print("   - Owner ID: ${profile['ownerId']}");
      print("   - Created: ${profile['createdAt']}");
      print("   - Updated: ${profile['updatedAt']}");
      
      // Check if approved
      if (profile['status'] == 'approved') {
        print("✅ Status: APPROVED - Ready to deliver!");
      } else if (profile['status'] == 'pending') {
        print("⏳ Status: PENDING - Waiting for admin approval");
      } else {
        print("❌ Status: ${profile['status']} - Unknown status");
      }
      
    } else {
      print("❌ No delivery partner profile found");
      print("💡 This could mean:");
      print("   - User hasn't signed up as delivery partner yet");
      print("   - Authentication issue");
      print("   - Profile not created");
    }
    
  } catch (e) {
    print("❌ Error retrieving delivery partner profile: $e");
  }
}
