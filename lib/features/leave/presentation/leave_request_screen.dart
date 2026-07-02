import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  String _leaveType = 'annual';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
          if (_endDate.isBefore(date)) _endDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Leave')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Leave Type
            const Text('Leave Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey700)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _leaveType,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.category)),
              items: const [
                DropdownMenuItem(value: 'annual', child: Text('Annual Leave')),
                DropdownMenuItem(value: 'sick', child: Text('Sick Leave')),
                DropdownMenuItem(value: 'personal', child: Text('Personal Leave')),
                DropdownMenuItem(value: 'maternity', child: Text('Maternity Leave')),
              ],
              onChanged: (v) => setState(() => _leaveType = v!),
            ),
            const SizedBox(height: 16),

            // Dates
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey700)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _pickDate(true),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(border: Border.all(color: AppColors.grey300), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18, color: AppColors.grey500),
                              const SizedBox(width: 8),
                              Text('${_startDate.day}/${_startDate.month}/${_startDate.year}', style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('End Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey700)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _pickDate(false),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(border: Border.all(color: AppColors.grey300), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18, color: AppColors.grey500),
                              const SizedBox(width: 8),
                              Text('${_endDate.day}/${_endDate.month}/${_endDate.year}', style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Reason
            const Text('Reason', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey700)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reasonController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe your reason for leave...',
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Leave request submitted')),
                );
                Navigator.pop(context);
              },
              child: const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }
}