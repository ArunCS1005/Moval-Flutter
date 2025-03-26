// const String baseUrl                              = 'http://archiveinfotechdevelopers.com/moval-admin/api';
const String baseUrl = 'https://dev.moval.techkrate.in/backend';
const String baseApiUrl = '$baseUrl/api';
const String loginUrl = '$baseApiUrl/empadmin/auth';
const String employeeSetPassword = '$baseApiUrl/employee/set-password/#employeeId';
const String adminSetPassword = '$baseApiUrl/admin/set-password';
const String branchSetPassword = '$baseApiUrl/workshop/set-password';
const String ilaPDFUrl = '$baseUrl/ilapdf';
const String workApprovalPDFUrl = '$baseUrl/viewpdf';
const String jobsMSList = '$baseApiUrl/jobms-app';
const String approveJobApi = '$baseApiUrl/inspection-jobstatus';
const String jobsMVList = '$baseApiUrl/job';
const String jobMSDetail = '$baseApiUrl/jobms/#jobId';
const String predictAIApi = 'http://192.64.83.204:8200/predict/';
const String jobMVDetail = '$baseApiUrl/job/#jobId';
const String uploadMSJobFile = '$baseApiUrl/mobile-app-file-upload';
const String submitMSJobImageOrVideo = '$baseApiUrl/mobile-app/manual-upload-docs';
const String submitMSJobSignatureUrl = '$baseApiUrl/mobile-app/upload-signature';
const String uploadMVJobFile = '$baseApiUrl/job/upload-image-video/#jobId';
const String submitMVJobImageOrVideo = '$baseApiUrl/job/submit-image-video/#jobId';
const String submitJobVehicleTechnicalDetail = '$baseApiUrl/job/#jobId';
const String updateMSJobDetailURL = '$baseApiUrl/jobms/#jobId';
const String vehicleDetailListApi = '$baseApiUrl/job/get-vehicle-detail';
const String vehicleVariantApi = '$baseApiUrl/job/vehicle-variants/#makerId';
const String branchList = '$baseApiUrl/branchall';
const String clientList = '$baseApiUrl/client/';
const String clientMSList = '$baseApiUrl/clientms';
const String sopUrl = '$baseApiUrl/sop';
const String jobFilesUrl = '$baseApiUrl/mobile-app/get-job-files';
const String clientFromBranchList = '$baseApiUrl/client-branchid';
const String workshopList = '$baseApiUrl/workshop-branchid';
const String clientBranchMSList = '$baseApiUrl/clientbranchms';
const String workshopBranchList = '$baseApiUrl/wsbranch_wid';
const String sopList = '$baseApiUrl/sop-branchid';
const String clientBranchList = '$baseApiUrl/clientbranch';
const String contactPersonList = '$baseApiUrl/contactperson';
const String contactPersonMSList = '$baseApiUrl/wbcontactbybranch';
const String employeeList = '$baseApiUrl/employee';
const String sendForgotPasswordRequest = '$baseApiUrl/employee/forgot-password';
const String verifyOtp = '$baseApiUrl/employee/verify-otp/#id';
const String addMSJob = '$baseApiUrl/jobms';
const String assignMSJobUrl = '$baseApiUrl/job-assign-ms';
const String addMVJob = '$baseApiUrl/job';
const String changePassword = '$baseApiUrl/employee/change-password';
const String filePrefix = '$baseApiUrl/storage/';

//------------------------------------ Jobs Status

const String pending = 'pending';
const String submitted = 'submitted';
const String approved = 'approved';
const String offline = 'offline';
const String rejected = 'rejected';

//------------------------------------ upload File Video/Image type

const String chassisNumber = 'Chassis Number';
const String frontView = 'Front View';
const String rearView = 'Rear View';
const String rightSide = 'Right Side';
const String leftSide = 'Left Side';
const String odometer = 'Odometer';
const String other = 'Other';
const String video = 'Video';

//------------------------------------ Detail Type ---
const String basicInfo = 'Basic Info';
const String vehicleDetail = 'Vehicle Detail';
const String technicalFeatures = 'Technical Features';

const String platformTypeMS = 'MS';
const String platformTypeMV = 'MV';

const allowDistanceToSubmitJob = 100;