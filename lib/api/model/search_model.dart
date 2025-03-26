// To parse this JSON data, do
//
//     final searchJobsList = searchJobsListFromJson(jsonString);

import 'dart:convert';

SearchJobsList searchJobsListFromJson(String str) =>
    SearchJobsList.fromJson(json.decode(str));

String searchJobsListToJson(SearchJobsList data) => json.encode(data.toJson());

class SearchJobsList {
  final bool success;
  final Result? result; // Nullable result
  final String message;

  SearchJobsList({
    required this.success,
    this.result, // Allow result to be null
    required this.message,
  });

  // Factory constructor to parse JSON data
  factory SearchJobsList.fromJson(Map<String, dynamic> json) => SearchJobsList(
        success: json["success"],
        result: json["result"] == null ? null : Result.fromJson(json["result"]),
        message: json["message"],
      );

  // Method to convert object to JSON
  Map<String, dynamic> toJson() => {
        "success": success,
        "result": result?.toJson(), // Return null if result is null
        "message": message,
      };
}

class Result {
  final List<Value> values;
  final Pagination pagination;

  Result({
    required this.values,
    required this.pagination,
  });

  factory Result.fromJson(Map<String, dynamic> json) {
    print("Parsing Result: ${json.toString()}");
    return Result(
      values: json["values"] != null
          ? List<Value>.from(json["values"].map((x) => Value.fromJson(x)))
          : [],
      pagination: Pagination.fromJson(json["pagination"]),
    );
  }

  Map<String, dynamic> toJson() => {
        "values": List<dynamic>.from(values.map((x) => x.toJson())),
        "pagination": pagination.toJson(),
      };
}

class Pagination {
  final int total;
  final int count;
  final int perPage;
  final int currentPage;
  final int totalPages;

  Pagination({
    required this.total,
    required this.count,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
        total: json["total"],
        count: json["count"],
        perPage: json["per_page"],
        currentPage: json["current_page"],
        totalPages: json["total_pages"],
      );

  Map<String, dynamic> toJson() => {
        "total": total,
        "count": count,
        "per_page": perPage,
        "current_page": currentPage,
        "total_pages": totalPages,
      };
}

class Value {
  final int id;
  final String claimType;
  final int jobRouteTo;
  final String jobRoute;
  final dynamic lossEstimate;
  final dynamic insurerLiability;
  final String vehicleRegNo;
  final String insuredName;
  final String placeSurvey;
  final dynamic officeCode;
  final int workshopId;
  final int workshopBranchId;
  final String contactPerson;
  final String contactNo;
  final String userRole;
  final int clientId;
  final int clientBranchId;
  final int jobassignedtoWorkshopEmpid;
  final int jobjssignedtoSurveyorEmpId;
  final String clientName;
  final int adminBranchId;
  final String branchName;
  final DateTime dateOfAppointment;
  final int sopId;
  final int createdBy;
  final String assignedTo;
  final String submittedBy;
  final String approvedBy;
  final String assignedBy;
  final DateTime assignedOn;
  final int uploadType;
  final int? updatedBy;
  final int noOfPhotos;
  final int noOfDocuments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String jobStatus;
  final String workshopName;
  final dynamic reportNo;
  final dynamic claimNo;
  final dynamic policyNo;

  Value({
    required this.id,
    required this.claimType,
    required this.jobRouteTo,
    required this.jobRoute,
    required this.lossEstimate,
    required this.insurerLiability,
    required this.vehicleRegNo,
    required this.insuredName,
    required this.placeSurvey,
    required this.officeCode,
    required this.workshopId,
    required this.workshopBranchId,
    required this.contactPerson,
    required this.contactNo,
    required this.userRole,
    required this.clientId,
    required this.clientBranchId,
    required this.jobassignedtoWorkshopEmpid,
    required this.jobjssignedtoSurveyorEmpId,
    required this.clientName,
    required this.adminBranchId,
    required this.branchName,
    required this.dateOfAppointment,
    required this.sopId,
    required this.createdBy,
    required this.assignedTo,
    required this.submittedBy,
    required this.approvedBy,
    required this.assignedBy,
    required this.assignedOn,
    required this.uploadType,
    required this.updatedBy,
    required this.noOfPhotos,
    required this.noOfDocuments,
    required this.createdAt,
    required this.updatedAt,
    required this.jobStatus,
    required this.workshopName,
    required this.reportNo,
    required this.claimNo,
    required this.policyNo,
  });

  factory Value.fromJson(Map<String, dynamic> json) => Value(
        id: json["id"],
        claimType: json["claim_type"],
        jobRouteTo: json["Job_Route_To"],
        jobRoute: json["Job_Route"],
        lossEstimate: json["loss_estimate"],
        insurerLiability: json["insurer_liability"],
        vehicleRegNo: json["vehicle_reg_no"],
        insuredName: json["insured_name"],
        placeSurvey: json["place_survey"],
        officeCode: json["office_code"],
        workshopId: json["workshop_id"],
        workshopBranchId: json["workshop_branch_id"],
        contactPerson: json["contact_person"],
        contactNo: json["contact_no"],
        userRole: json["user_role"],
        clientId: json["client_id"],
        clientBranchId: json["client_branch_id"],
        jobassignedtoWorkshopEmpid: json["jobassignedto_workshopEmpid"],
        jobjssignedtoSurveyorEmpId: json["jobjssignedto_surveyorEmpId"],
        clientName: json["client_name"],
        adminBranchId: json["admin_branch_id"],
        branchName: json["branch_name"],
        dateOfAppointment: DateTime.parse(json["date_of_appointment"]),
        sopId: json["sop_id"],
        createdBy: json["created_by"],
        assignedTo: json["assigned_to"],
        submittedBy: json["submitted_by"],
        approvedBy: json["approved_by"],
        assignedBy: json["assigned_by"],
        assignedOn: DateTime.parse(json["assigned_on"]),
        uploadType: json["upload_type"],
        updatedBy: json["updated_by"],
        noOfPhotos: json["no_of_photos"],
        noOfDocuments: json["no_of_documents"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        jobStatus: json["job_status"],
        workshopName: json["workshop_name"],
        reportNo: json["report_no"],
        claimNo: json["claim_no"],
        policyNo: json["policy_no"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "claim_type": claimType,
        "Job_Route_To": jobRouteTo,
        "Job_Route": jobRoute,
        "loss_estimate": lossEstimate,
        "insurer_liability": insurerLiability,
        "vehicle_reg_no": vehicleRegNo,
        "insured_name": insuredName,
        "place_survey": placeSurvey,
        "office_code": officeCode,
        "workshop_id": workshopId,
        "workshop_branch_id": workshopBranchId,
        "contact_person": contactPerson,
        "contact_no": contactNo,
        "user_role": userRole,
        "client_id": clientId,
        "client_branch_id": clientBranchId,
        "jobassignedto_workshopEmpid": jobassignedtoWorkshopEmpid,
        "jobjssignedto_surveyorEmpId": jobjssignedtoSurveyorEmpId,
        "client_name": clientName,
        "admin_branch_id": adminBranchId,
        "branch_name": branchName,
        "date_of_appointment":
            "${dateOfAppointment.year.toString().padLeft(4, '0')}-${dateOfAppointment.month.toString().padLeft(2, '0')}-${dateOfAppointment.day.toString().padLeft(2, '0')}",
        "sop_id": sopId,
        "created_by": createdBy,
        "assigned_to": assignedTo,
        "submitted_by": submittedBy,
        "approved_by": approvedBy,
        "assigned_by": assignedBy,
        "assigned_on": assignedOn.toIso8601String(),
        "upload_type": uploadType,
        "updated_by": updatedBy,
        "no_of_photos": noOfPhotos,
        "no_of_documents": noOfDocuments,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "job_status": jobStatus,
        "workshop_name": workshopName,
        "report_no": reportNo,
        "claim_no": claimNo,
        "policy_no": policyNo,
      };
}
