import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/database_service.dart';

class ApprovalStatusWidget extends StatelessWidget {
  final String userId;
  final String requestId;

  const ApprovalStatusWidget({
    Key? key,
    required this.userId,
    required this.requestId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: DatabaseService.instance
          .customerCartRef(userId)
          .child(requestId)
          .onValue,
      builder: (context, snapshot) {
        bool isApproved = false;
        
        if (snapshot.hasData && snapshot.data!.snapshot.value is Map) {
          final data = snapshot.data!.snapshot.value as Map;
          isApproved = data['approved'] == true || 
                     data['status'] == 'approved' || 
                     data['pendingApproval'] == false;
        }
        
        return Text(
          isApproved 
            ? 'Approved by pharmacist'
            : 'Pending pharmacist approval',
          style: TextStyle(
            color: isApproved ? Colors.green : Colors.orange,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }
}