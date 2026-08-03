enum JobStatus { newJob, accepted, inProgress, completed, cancelled }

JobStatus jobStatusFromString(String s) {
  switch (s) {
    case 'new':
      return JobStatus.newJob;
    case 'accepted':
      return JobStatus.accepted;
    case 'in_progress':
      return JobStatus.inProgress;
    case 'completed':
      return JobStatus.completed;
    case 'cancelled':
      return JobStatus.cancelled;
  }
  return JobStatus.newJob;
}

class Job {
  final int id;
  final String customer;
  final String address;
  final String phone;
  final String service;
  final String type;
  final String duration;
  final int amount;
  JobStatus status;
  final String time;
  final String notes;
  final String distance;
  final String paymentMode;
  int? rating;
  String? beforePhoto;
  String? afterPhoto;
  String? otp;

  Job({
    required this.id,
    required this.customer,
    required this.address,
    required this.phone,
    required this.service,
    required this.type,
    required this.duration,
    required this.amount,
    required this.status,
    required this.time,
    this.notes = '',
    required this.distance,
    required this.paymentMode,
    this.rating,
    this.beforePhoto,
    this.afterPhoto,
    this.otp,
  });

  String get timeShort {
    final parts = time.split('•');
    return parts.length > 1 ? parts[1].trim() : time;
  }

  String get addressShort => address.split(',').first;
}

List<Job> sampleJobs() => [
      Job(
        id: 101,
        customer: 'Priya Sharma',
        address: 'B-402, Ramdev Park CHS, Phase-1, Mira Road East',
        phone: '+91 98201 55432',
        service: 'Electrician',
        type: 'Ceiling Fan Installation + Switchboard',
        duration: '50 mins',
        amount: 650,
        status: JobStatus.newJob,
        time: 'Today • 4:15 PM',
        notes: 'Need 2 new fans installed. Customer has already purchased the fans.',
        distance: '0.9 km',
        paymentMode: 'UPI',
      ),
      Job(
        id: 102,
        customer: 'Rajesh Kulkarni',
        address: 'A-107, Indralok CHS, Mira Road',
        phone: '+91 98765 11234',
        service: 'Plumber',
        type: 'Kitchen Sink Leakage Repair',
        duration: '35 mins',
        amount: 420,
        status: JobStatus.newJob,
        time: 'Today • 5:00 PM',
        notes: 'Water leaking under the sink. Urgent.',
        distance: '1.8 km',
        paymentMode: 'Cash',
      ),
      Job(
        id: 103,
        customer: 'Anita Desai',
        address: 'C-204, Raj Splendor CHS, Bhayandar West',
        phone: '+91 70213 88901',
        service: 'AC Repair',
        type: 'Split AC Gas Refill + Servicing',
        duration: '65 mins',
        amount: 1250,
        status: JobStatus.newJob,
        time: 'Tomorrow • 10:30 AM',
        notes: 'AC not cooling properly. Last serviced 8 months ago.',
        distance: '4.3 km',
        paymentMode: 'UPI',
      ),
      Job(
        id: 104,
        customer: 'Vikram Patil',
        address: 'Shop No. 12, Medatiya Nagar Market, Mira Road',
        phone: '+91 97654 33211',
        service: 'Appliance Repair',
        type: 'Washing Machine Drum Not Spinning',
        duration: '45 mins',
        amount: 580,
        status: JobStatus.accepted,
        time: 'Today • 2:45 PM',
        notes: 'LG 8kg front load. Error code E3.',
        distance: '2.1 km',
        paymentMode: 'UPI',
      ),
      Job(
        id: 105,
        customer: 'Meena Joshi',
        address: 'D-501, Shri Ramdev Park CHS, Mira Road East',
        phone: '+91 80802 44556',
        service: 'Carpenter',
        type: 'Modular Kitchen Drawer Repair',
        duration: '40 mins',
        amount: 380,
        status: JobStatus.accepted,
        time: 'Today • 6:30 PM',
        notes: 'Drawer slider broken. Need replacement if possible.',
        distance: '0.6 km',
        paymentMode: 'Cash',
      ),
      Job(
        id: 106,
        customer: 'Sanjay Rane',
        address: 'Row House 17, Kenwood Park, Mira Road',
        phone: '+91 98989 77665',
        service: 'Pest Control',
        type: 'Full Home Cockroach + Termite Treatment',
        duration: '90 mins',
        amount: 1850,
        status: JobStatus.inProgress,
        time: 'Today • 11:00 AM',
        notes: '3BHK apartment. Customer wants gel treatment + spray.',
        distance: '3.4 km',
        paymentMode: 'UPI',
        beforePhoto: 'https://picsum.photos/id/1015/400/300',
      ),
      Job(
        id: 107,
        customer: 'Kavita Nair',
        address: '102, Omkar CHS, Bhayandar East',
        phone: '+91 70456 99112',
        service: 'Electrician',
        type: 'MCB Tripping Issue + Full Flat Inspection',
        duration: '55 mins',
        amount: 720,
        status: JobStatus.completed,
        time: 'Yesterday • 3:20 PM',
        notes: 'Frequent tripping. Found loose connection in distribution box.',
        distance: '5.1 km',
        paymentMode: 'UPI',
        rating: 5,
        beforePhoto: 'https://picsum.photos/id/160/400/300',
        afterPhoto: 'https://picsum.photos/id/201/400/300',
        otp: '482913',
      ),
      Job(
        id: 108,
        customer: 'Ramesh Iyer',
        address: 'B-301, Golden Nest CHS, Mira Road',
        phone: '+91 93214 55678',
        service: 'Plumber',
        type: 'Bathroom Geyser Installation',
        duration: '70 mins',
        amount: 950,
        status: JobStatus.completed,
        time: 'Jan 15 • 11:45 AM',
        distance: '1.5 km',
        paymentMode: 'UPI',
        rating: 4,
        afterPhoto: 'https://picsum.photos/id/251/400/300',
        otp: '771902',
      ),
      Job(
        id: 109,
        customer: 'Pooja Malhotra',
        address: 'Flat 804, Regency Tower, Mira Road East',
        phone: '+91 88765 44321',
        service: 'Cleaning',
        type: 'Deep Home Cleaning (Post Renovation)',
        duration: '3 hrs',
        amount: 2400,
        status: JobStatus.completed,
        time: 'Jan 14 • 9:00 AM',
        notes: 'Full 2BHK deep clean after painting work.',
        distance: '2.8 km',
        paymentMode: 'UPI',
        rating: 5,
        beforePhoto: 'https://picsum.photos/id/29/400/300',
        afterPhoto: 'https://picsum.photos/id/160/400/300',
        otp: '334455',
      ),
      Job(
        id: 110,
        customer: 'Deepak More',
        address: 'G-1, Ramdev Park CHS, Mira Road',
        phone: '+91 70289 33445',
        service: 'Electrician',
        type: 'Society Common Area Lighting Repair',
        duration: '25 mins',
        amount: 300,
        status: JobStatus.cancelled,
        time: 'Jan 12 • 5:30 PM',
        notes: 'Customer cancelled due to change of plan.',
        distance: '0.4 km',
        paymentMode: 'UPI',
      ),
      Job(
        id: 111,
        customer: 'Sunita Kulkarni',
        address: 'B-1204, Ramdev Park CHS Phase-2, Mira Road East',
        phone: '+91 98765 44321',
        service: 'Water Purifier',
        type: 'RO+UV Installation + High TDS Water Test',
        duration: '75 mins',
        amount: 2450,
        status: JobStatus.newJob,
        time: 'Today • 6:45 PM',
        notes:
            'New Lumino Monsoon Champions model. High TDS area - please test water before install. Society gate entry from main road.',
        distance: '1.2 km',
        paymentMode: 'UPI',
      ),
    ];

class GpsErrorType {
  final String type;
  final String label;
  final String desc;
  const GpsErrorType(this.type, this.label, this.desc);
}

const List<GpsErrorType> gpsErrorTypes = [
  GpsErrorType('weak_signal', 'Weak GPS Signal', 'Location accuracy reduced in high-rise area'),
  GpsErrorType('gps_unavailable', 'GPS Temporarily Unavailable', 'Satellite connection lost'),
  GpsErrorType('inaccurate_location', 'Inaccurate Location', 'Pin placed 150m off - common in dense societies'),
  GpsErrorType('battery_saver', 'Battery Saver Mode Active', 'Reduced GPS precision'),
  GpsErrorType('network_congestion', 'Network Congestion', 'Data sync delayed in Mira Road area'),
  GpsErrorType('permission_denied', 'Location Permission Issue', 'App location access restricted'),
  GpsErrorType('weather_interference', 'Weather Interference (Monsoon)', 'Heavy rain affecting signal'),
  GpsErrorType('society_gate', 'Society Gate Access Issue', 'GPS blocked inside gated community'),
];

class TrackingError {
  final int jobId;
  final String service;
  final String errorType;
  final String timestamp;
  TrackingError({
    required this.jobId,
    required this.service,
    required this.errorType,
    required this.timestamp,
  });
}

class Society {
  final String name;
  final String phase;
  final String area;
  final int units;
  final String contact;
  final String phone;
  final bool amc;
  final int activeJobs;
  final double rating;
  final String access;

  const Society({
    required this.name,
    this.phase = '',
    required this.area,
    required this.units,
    required this.contact,
    required this.phone,
    required this.amc,
    required this.activeJobs,
    required this.rating,
    required this.access,
  });
}

const List<Society> societyData = [
  Society(
    name: 'Ramdev Park CHS',
    phase: 'Phase 1',
    area: 'Mira Road East',
    units: 240,
    contact: 'Sec. Bharat Mehta',
    phone: '+91 98200 11234',
    amc: true,
    activeJobs: 3,
    rating: 4.8,
    access: 'Gate B – show Partner ID',
  ),
  Society(
    name: 'Indralok CHS',
    area: 'Mira Road',
    units: 180,
    contact: 'Mgr. Sunil Joshi',
    phone: '+91 70210 55678',
    amc: true,
    activeJobs: 1,
    rating: 4.6,
    access: 'Main gate; call security',
  ),
  Society(
    name: 'Raj Splendor',
    area: 'Bhayandar West',
    units: 312,
    contact: 'Sec. Kavita Nair',
    phone: '+91 98765 44321',
    amc: false,
    activeJobs: 2,
    rating: 4.5,
    access: 'Gate 1 only (6 AM–10 PM)',
  ),
  Society(
    name: 'Shiv Sai CHS',
    area: 'Mira Road East',
    units: 96,
    contact: 'Ch. Dinesh Sawant',
    phone: '+91 91234 77890',
    amc: true,
    activeJobs: 0,
    rating: 4.9,
    access: 'Single gate; buzz flat',
  ),
  Society(
    name: 'Green Valley',
    phase: 'Tower A',
    area: 'Mira Road',
    units: 420,
    contact: 'Mgr. Pooja Desai',
    phone: '+91 99670 33210',
    amc: true,
    activeJobs: 1,
    rating: 4.7,
    access: 'North gate; visitor pass req.',
  ),
  Society(
    name: 'Harmony Heights',
    area: 'Bhayandar East',
    units: 156,
    contact: 'Sec. Rahul Patil',
    phone: '+91 98201 88456',
    amc: false,
    activeJobs: 0,
    rating: 4.4,
    access: 'Main gate; WhatsApp guard',
  ),
];
