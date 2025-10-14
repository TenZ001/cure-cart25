import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';
import 'login_screen.dart';
import 'package:country_code_picker/country_code_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  // Delivery-specific
  final TextEditingController vehicleTypeController = TextEditingController();
  final TextEditingController vehicleNumberController = TextEditingController();
  final TextEditingController nicController = TextEditingController();
  final TextEditingController emergencyNameController = TextEditingController();
  final TextEditingController emergencyPhoneController = TextEditingController();

  String? selectedRole;
  String? selectedVehicleType;
  final ApiService apiService = ApiService();
  bool _loading = false;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Passwords do not match")));
      return;
    }

    setState(() => _loading = true);

    apiService.setPendingRegisterExtras({
      "phone": phoneController.text.trim(),
      "address": addressController.text.trim(),
      "dob": dobController.text.trim(),
      "vehicleType": selectedRole == 'delivery' ? selectedVehicleType : null,
      "vehicleNumber": selectedRole == 'delivery' ? vehicleNumberController.text.trim() : null,
      "nic": selectedRole == 'delivery' ? nicController.text.trim() : null,
      "emergencyContactName": selectedRole == 'delivery' ? emergencyNameController.text.trim() : null,
      "emergencyContactPhone": selectedRole == 'delivery' ? emergencyPhoneController.text.trim() : null,
    });

    try {
      final success = await apiService.registerUser(
        nameController.text.trim(),
        emailController.text.trim(),
        passwordController.text.trim(),
        (selectedRole ?? "patient"),
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Registered successfully! Please login."),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Registration failed: ${e is Exception ? e.toString().replaceFirst('Exception: ', '') : e}")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        dobController.text =
            "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF9FAFB), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Cure Cart Logo with circular gradient outline
                Container(
                  width: 100,
                  height: 100,
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.green, Colors.blue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset("assets/curecart_logo.png", height: 60),
                  ),
                ),
                const SizedBox(height: 20),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Create an Account",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 20),

                // Full Name
                _buildTextField("Full Name", nameController),
                const SizedBox(height: 15),

                // Email
                _buildTextField(
                  "Email Address",
                  emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),

                // Phone with country picker
                Row(
                  children: [
                    CountryCodePicker(
                      onChanged: (country) {
                        print("Selected country code: ${country.dialCode}");
                      },
                      initialSelection: 'LK', // Default Sri Lanka
                      favorite: const ['+94', 'LK'],
                      showCountryOnly: false,
                      showOnlyCountryWhenClosed: false,
                      alignLeft: false,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.number,
                        maxLength: 9, // 9 digits for SL numbers
                        decoration: InputDecoration(
                          counterText: "",
                          hintText: "Phone Number",
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "⚠️ Please enter phone number";
                          } else if (value.length != 9) {
                            return "⚠️ Phone number must be 9 digits";
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15), // 👈 Added spacing here
                // Role Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black26),
                  ),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(border: InputBorder.none),
                    initialValue: selectedRole,
                    hint: const Text("Select Your Role"),
                    items: const [
                      DropdownMenuItem(
                        value: "patient",
                        child: Text("Patient"),
                      ),
                      DropdownMenuItem(
                        value: "delivery",
                        child: Text("Delivery"),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? "⚠️ Please select your role" : null,
                  ),
                ),
                const SizedBox(height: 15),

                if (selectedRole == 'delivery') ...[
                  // Vehicle Type dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black26),
                    ),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(border: InputBorder.none),
                      initialValue: selectedVehicleType,
                      hint: const Text("Select Vehicle Type"),
                      items: const [
                        DropdownMenuItem(value: "bike", child: Text("Bike")),
                        DropdownMenuItem(value: "car", child: Text("Car")),
                        DropdownMenuItem(value: "van", child: Text("Van")),
                        DropdownMenuItem(value: "other", child: Text("Other")),
                      ],
                      onChanged: (v) => setState(() => selectedVehicleType = v),
                      validator: (v) => v == null || v.isEmpty ? "⚠️ Please select vehicle type" : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField("Vehicle Number", vehicleNumberController),
                  const SizedBox(height: 12),
                  // NIC numeric only, max 12
                  TextFormField(
                    controller: nicController,
                    keyboardType: TextInputType.number,
                    maxLength: 12,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      counterText: "",
                      hintText: "NIC (12 digits)",
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return "⚠️ Please enter NIC";
                      if (value.length != 12) return "⚠️ NIC must be 12 digits";
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField("Emergency Contact Name", emergencyNameController),
                  const SizedBox(height: 12),
                  _buildTextField("Emergency Contact Phone", emergencyPhoneController, keyboardType: TextInputType.phone),
                  const SizedBox(height: 15),
                ],

                // Address
                _buildTextField("Address", addressController),
                const SizedBox(height: 15),

                // Date of Birth with calendar picker
                TextFormField(
                  controller: dobController,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: InputDecoration(
                    suffixIcon: const Icon(Icons.calendar_today, size: 18),
                    hintText: "Date of Birth",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? "⚠️ Please select your date of birth"
                      : null,
                ),
                const SizedBox(height: 15),

                // Password with eye icon
                TextFormField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: "Password",
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? "⚠️ Please enter password"
                      : null,
                ),
                const SizedBox(height: 15),

                // Confirm Password with eye icon
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: "Confirm Password",
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? "⚠️ Please confirm password"
                      : null,
                ),
                const SizedBox(height: 25),

                // Continue Button
                _loading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _register,
                          child: const Text(
                            "Continue",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: 15),

                // Login Now Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      "Login Now",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    TextEditingController controller, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? "⚠️ Please enter $hint" : null,
    );
  }
}
