import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/notification_dot_controller.dart';
import '../controller/user_controller.dart';
import '../helpers/route_helper.dart';
import '../utilities/app_constans.dart';
import '../model/appointment_model.dart';
import '../model/clinic_model.dart';
import '../model/family_members_model.dart';
import '../services/appointment_service.dart';
import '../services/clinic_service.dart';
import '../services/family_members_service.dart';
import '../utilities/api_content.dart';
import '../utilities/clinic_config.dart';
import '../utilities/colors_constant.dart';
import '../utilities/sharedpreference_constants.dart';
import '../widget/appointment_only_back_guard.dart';
import '../widget/drawer_widget.dart';
import '../widget/image_box_widget.dart';
import 'home_page.dart';

/// Home page for the appointment-only flow. Five tabs:
///   1. Booking         → clinics with expandable doctor lists
///   2. My Appointments → 3 sub-tabs (past / today / upcoming) with the
///                        same colour-coded borders as medicare-doctor-app
///   3. My Doctors      → derived from the user's appointments (placeholder
///                        until a dedicated endpoint exists)
///   4. Family          → list of FamilyMembersModel
///   5. Dashboard       → placeholder counters until a user dashboard
///                        endpoint exists
///
/// Falls back to the legacy [HomePage] when ClinicConfig.showAppointmentOnly
/// is false.
class AppointmentOnlyHomePage extends StatefulWidget {
  const AppointmentOnlyHomePage({super.key});

  @override
  State<AppointmentOnlyHomePage> createState() =>
      _AppointmentOnlyHomePageState();
}

class _AppointmentOnlyHomePageState extends State<AppointmentOnlyHomePage> {
  // Per-tab loading + caches.
  bool _clinicsLoading = true;
  List<ClinicModel> _clinics = [];

  bool _appointmentsLoading = true;
  List<AppointmentModel> _appointments = [];

  bool _familyLoading = true;
  List<FamilyMembersModel> _family = [];

  // Identity card on the My Appointments tab.
  String _userName = '';
  String _userId = '';

  // Initial tabs — overridden via Get.arguments by the booking flow when it
  // redirects here after a successful appointment creation.
  // outer: 0=Booking, 1=My Appointments, 2=Doctors, 3=Family, 4=Dashboard.
  int _initialOuterTab = 0;
  // sub-tab inside My Appointments: 0=past, 1=today, 2=future.
  int _initialAppointmentSubTab = 1;

  // Mis Citas filters (only rendered when _clinics.length > 1).
  int? _filterClinicId; // null => all clinics
  DateTime? _filterStart; // null => no lower bound
  DateTime? _filterEnd; // null => no upper bound

  @override
  void initState() {
    super.initState();
    _readNavigationArguments();
    if (ClinicConfig.showAppointmentOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadIdentity();
        _loadClinics();
        _loadAppointments();
        _loadFamily();
      });
    }
  }

  void _readNavigationArguments() {
    final args = Get.arguments;
    if (args is! Map) return;
    final tab = args['tab']?.toString();
    if (tab == 'appointments') _initialOuterTab = 1;
    if (tab == 'doctors') _initialOuterTab = 2;
    if (tab == 'family') _initialOuterTab = 3;
    if (tab == 'dashboard') _initialOuterTab = 4;
    final subTab = args['subTab']?.toString();
    if (subTab == 'past') _initialAppointmentSubTab = 0;
    if (subTab == 'today') _initialAppointmentSubTab = 1;
    if (subTab == 'future') _initialAppointmentSubTab = 2;
  }

  Future<void> _loadIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    // Prefer patient_id (the real "paciente"); fall back to user id when
    // the account hasn't been linked to a patient row yet.
    final pid = prefs.getString(SharedPreferencesConstants.patientId) ?? '';
    final uid = prefs.getString(SharedPreferencesConstants.uid) ?? '';
    debugPrint('_loadIdentity: prefs.patient_id="$pid" prefs.uid="$uid"');
    setState(() {
      _userId = pid.isNotEmpty && pid != 'null' ? pid : uid;
      _userName = prefs.getString(SharedPreferencesConstants.name) ?? '';
    });
  }

  Future<void> _loadClinics() async {
    if (!mounted) return;
    setState(() => _clinicsLoading = true);
    final list = await ClinicService.getData();
    if (!mounted) return;
    setState(() {
      _clinics = list ?? [];
      _clinicsLoading = false;
    });
  }

  Future<void> _loadAppointments() async {
    if (!mounted) return;
    setState(() => _appointmentsLoading = true);
    final list = await AppointmentService.getData();
    if (!mounted) return;
    setState(() {
      _appointments = list ?? [];
      _appointmentsLoading = false;
    });
  }

  Future<void> _loadFamily() async {
    if (!mounted) return;
    setState(() => _familyLoading = true);
    final list = await FamilyMembersService.getData();
    if (!mounted) return;
    setState(() {
      _family = list ?? [];
      _familyLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!ClinicConfig.showAppointmentOnly) {
      return const HomePage();
    }

    return AppointmentOnlyBackGuard(
      child: DefaultTabController(
        length: 5,
        initialIndex: _initialOuterTab,
        child: Scaffold(
          drawer: _buildDrawer(),
          appBar: AppBar(
            backgroundColor: ColorResources.primaryColor,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              "booking".tr,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  Get.toNamed(RouteHelper.getNotificationPageRoute());
                },
              ),
            ],
            bottom: TabBar(
              isScrollable: true,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(icon: const Icon(Icons.local_hospital), text: "booking".tr),
                Tab(icon: const Icon(Icons.event_note), text: "my_appointments".tr),
                Tab(icon: const Icon(Icons.medical_services), text: "my_doctors".tr),
                Tab(icon: const Icon(Icons.family_restroom), text: "family".tr),
                Tab(icon: const Icon(Icons.dashboard), text: "tab_dashboard".tr),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _buildBookingTab(),
              _buildAppointmentsTab(),
              _buildMyDoctorsTab(),
              _buildFamilyTab(),
              _buildDashboardTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildDrawer() {
    try {
      final userController = Get.find<UserController>(tag: "user");
      final notif =
          Get.find<NotificationDotController>(tag: "notification_dot");
      return IDrawerWidget()
          .buildDrawerWidget(userController, notif, false);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 1) Booking — list of clinics, tap to expand and lazy-load doctors.
  // ---------------------------------------------------------------------------

  Widget _buildBookingTab() {
    if (_clinicsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_clinics.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadClinics,
        child: ListView(
          children: [
            const SizedBox(height: 80),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "no_clinics_found".tr,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      );
    }
    // Single-clinic deployments: skip the ExpansionTile and show a flat
    // layout with the clinic info on top and the doctor list right below.
    // (When the single clinic also has a single doctor, _loadClinics has
    // already redirected to DoctorsDetailsPage via _maybeAutoJumpSingleDoctor.)
    if (_clinics.length == 1) {
      return RefreshIndicator(
        onRefresh: _loadClinics,
        child: _SingleClinicView(clinic: _clinics.first),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadClinics,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _clinics.length,
        itemBuilder: (_, i) => _ClinicExpandableCard(clinic: _clinics[i]),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2) My Appointments — identity card + 3 sub-tabs.
  // ---------------------------------------------------------------------------

  Widget _buildAppointmentsTab() {
    return DefaultTabController(
      length: 3,
      initialIndex: _initialAppointmentSubTab,
      child: Column(
        children: [
          _buildIdentityCard(),
          _buildAppointmentFilters(),
          Material(
            color: Colors.white,
            child: TabBar(
              labelColor: ColorResources.primaryColor,
              unselectedLabelColor: Colors.black54,
              indicatorColor: ColorResources.primaryColor,
              tabs: [
                Tab(text: "tab_past".tr),
                Tab(text: "tab_today".tr),
                Tab(text: "tab_future".tr),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildAppointmentsList(_AppointmentMode.past),
                _buildAppointmentsList(_AppointmentMode.today),
                _buildAppointmentsList(_AppointmentMode.future),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentFilters() {
    final df = DateFormat('yyyy-MM-dd');
    final hasAnyFilter = _filterClinicId != null ||
        _filterStart != null ||
        _filterEnd != null;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clinic dropdown only when there is more than one clinic to choose
          // from — otherwise the picker would always have a single option and
          // clutter the view.
          if (_clinics.length > 1)
            Row(
              children: [
                const Icon(Icons.filter_list,
                    size: 18, color: ColorResources.primaryColor),
                const SizedBox(width: 6),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _filterClinicId,
                      isExpanded: true,
                      isDense: true,
                      hint: Text(
                        "all_clinics".tr,
                        style: const TextStyle(fontSize: 13),
                      ),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text(
                            "all_clinics".tr,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        ..._clinics.map(
                          (c) => DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(
                              c.title ?? '#${c.id}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _filterClinicId = v),
                    ),
                  ),
                ),
              ],
            ),
          Row(
            children: [
              Expanded(
                child: _buildDateChip(
                  label: "from_date".tr,
                  value: _filterStart == null
                      ? null
                      : df.format(_filterStart!),
                  onTap: () => _pickFilterDate(isStart: true),
                  onClear: _filterStart == null
                      ? null
                      : () => setState(() => _filterStart = null),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildDateChip(
                  label: "to_date".tr,
                  value: _filterEnd == null ? null : df.format(_filterEnd!),
                  onTap: () => _pickFilterDate(isStart: false),
                  onClear: _filterEnd == null
                      ? null
                      : () => setState(() => _filterEnd = null),
                ),
              ),
              if (hasAnyFilter)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: "clear_filters".tr,
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() {
                    _filterClinicId = null;
                    _filterStart = null;
                    _filterEnd = null;
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip({
    required String label,
    required String? value,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black26),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.date_range,
                size: 16, color: ColorResources.primaryColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value ?? label,
                style: TextStyle(
                  fontSize: 12,
                  color: value == null ? Colors.black54 : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close,
                    size: 14, color: Colors.black54),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFilterDate({required bool isStart}) async {
    final initial = (isStart ? _filterStart : _filterEnd) ?? DateTime.now();
    final firstDate = DateTime(2020, 1, 1);
    final lastDate = DateTime.now().add(const Duration(days: 365 * 5));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _filterStart = picked;
        // If end was set and is now before start, push it forward.
        if (_filterEnd != null && _filterEnd!.isBefore(picked)) {
          _filterEnd = picked;
        }
      } else {
        _filterEnd = picked;
        if (_filterStart != null && picked.isBefore(_filterStart!)) {
          _filterStart = picked;
        }
      }
    });
  }

  Widget _buildIdentityCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: ColorResources.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName.isEmpty ? '-' : _userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${"patient_id".tr}: ${_userId.isEmpty ? '-' : _userId}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(_AppointmentMode mode) {
    if (_appointmentsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final filtered = _filterAndSortAppointments(_appointments, mode);
    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAppointments,
        child: ListView(
          children: [
            const SizedBox(height: 80),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "no_appointment_found".tr,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: filtered.length,
        itemBuilder: (_, i) => _buildAppointmentCard(filtered[i]),
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel a) {
    final color = _typeColor(a);
    return GestureDetector(
      onTap: () {
        if (a.id != null) {
          Get.toNamed(
            RouteHelper.getAppointmentDetailsPageRoute(
              appId: a.id.toString(),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: color, width: 5)),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 2),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "${a.doctFName ?? ''} ${a.doctLName ?? ''}".trim().isEmpty
                        ? '#${a.id}'
                        : "${a.doctFName ?? ''} ${a.doctLName ?? ''}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  a.status ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Patient name + patient_id from the appointment row, so the
            // user sees whose appointment this is (their own or a family
            // member's).
            Builder(
              builder: (_) {
                final patientLine = [
                  "${a.pFName ?? ''} ${a.pLName ?? ''}".trim(),
                  if (a.patientId != null) '#${a.patientId}',
                ].where((s) => s.isNotEmpty).join('  ·  ');
                if (patientLine.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    patientLine,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
            Text(
              '${a.date ?? '-'}  ·  ${a.timeSlot ?? ''}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            if ((a.type ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  a.type!,
                  style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3) My Doctors — derived from the user's appointments (no dedicated
  //    endpoint yet).
  // ---------------------------------------------------------------------------

  Widget _buildMyDoctorsTab() {
    if (_appointmentsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final seen = <int, AppointmentModel>{};
    for (final a in _appointments) {
      if (a.doctorId != null && !seen.containsKey(a.doctorId)) {
        seen[a.doctorId!] = a;
      }
    }
    if (seen.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            "no_doctor_found".tr,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }
    final list = seen.values.toList();
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final a = list[i];
        final hasImage = (a.doctImage ?? '').isNotEmpty;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            onTap: a.doctorId == null
                ? null
                : () => Get.toNamed(
                      RouteHelper.getDoctorsDetailsPageRoute(
                        doctId: a.doctorId.toString(),
                        clinicId: a.clinicId?.toString(),
                      ),
                    ),
            leading: SizedBox(
              width: 48,
              height: 48,
              child: ClipOval(
                child: hasImage
                    ? ImageBoxFillWidget(
                        imageUrl: '${ApiContents.imageUrl}/${a.doctImage}',
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.person, size: 28),
                      ),
              ),
            ),
            title: Text(
              "${a.doctFName ?? ''} ${a.doctLName ?? ''}".trim().isEmpty
                  ? '#${a.doctorId}'
                  : "${a.doctFName ?? ''} ${a.doctLName ?? ''}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              a.doctSpecialization ?? '',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 4) Family — list of family members from FamilyMembersService.
  //    NOTE: when the backend gets the per-clinic endpoint, swap the fetch
  //    inside _loadFamily(); the rest stays the same.
  // ---------------------------------------------------------------------------

  Widget _buildFamilyTab() {
    if (_familyLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _loadFamily,
      child: _family.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.family_restroom,
                            size: 60, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(
                          "no_family_members".tr,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _family.length,
              itemBuilder: (_, i) {
                final f = _family[i];
                final fullName = "${f.fName ?? ''} ${f.lName ?? ''}".trim();
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    onTap: () {
                      Get.toNamed(RouteHelper.getFamilyMemberListPageRoute());
                    },
                    leading: const CircleAvatar(
                      backgroundColor: Colors.indigo,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      fullName.isEmpty ? '#${f.id}' : fullName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      [
                        if ((f.gender ?? '').isNotEmpty) f.gender!,
                        if ((f.dob ?? '').isNotEmpty) f.dob!,
                      ].join(' · '),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              },
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5) Dashboard — placeholder counters until a user-side dashboard endpoint
  //    exists. We derive what we can from the appointments list.
  // ---------------------------------------------------------------------------

  Widget _buildDashboardTab() {
    if (_appointmentsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final today = _todayString();
    final total = _appointments.length;
    final todayCount =
        _appointments.where((a) => (a.date ?? '') == today).length;
    final upcoming = _appointments
        .where((a) => (a.date ?? '').compareTo(today) > 0)
        .length;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _statCard("appointment".tr, total.toString(), Icons.event,
            Colors.indigo),
        _statCard("today".tr, todayCount.toString(), Icons.today,
            Colors.orange),
        _statCard("tab_future".tr, upcoming.toString(), Icons.schedule,
            Colors.green),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers.
  // ---------------------------------------------------------------------------

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Maps appointment.type to a brand colour matching the doctor-app borders.
  Color _typeColor(AppointmentModel a) {
    final t = (a.type ?? '').toLowerCase();
    if (t.contains('video')) return Colors.blue.shade600;
    if (t.contains('emergency') || t.contains('emerg')) {
      return Colors.purple.shade600;
    }
    if (t.contains('opd') || t.contains('clinic')) {
      return Colors.green.shade600;
    }
    if (a.isVideoConsult == true) return Colors.blue.shade600;
    return Colors.grey.shade400;
  }

  static DateTime? _appointmentEnd(AppointmentModel a) {
    final dateStr = a.date;
    final slot = a.timeSlot;
    if (dateStr == null || dateStr.isEmpty || slot == null || slot.isEmpty) {
      return null;
    }
    final dayPart = DateTime.tryParse(dateStr);
    if (dayPart == null) return null;
    final firstChunk = slot.split('-').first.trim().toUpperCase();
    final isPm = firstChunk.endsWith('PM');
    final isAm = firstChunk.endsWith('AM');
    final cleaned =
        firstChunk.replaceAll('AM', '').replaceAll('PM', '').trim();
    final hm = cleaned.split(':');
    if (hm.length < 2) return null;
    int? h = int.tryParse(hm[0]);
    final m = int.tryParse(hm[1]);
    if (h == null || m == null) return null;
    if (isPm && h < 12) h += 12;
    if (isAm && h == 12) h = 0;
    return DateTime(dayPart.year, dayPart.month, dayPart.day, h, m)
        .add(Duration(minutes: a.durationMinutes ?? 30));
  }

  List<AppointmentModel> _filterAndSortAppointments(
    List<AppointmentModel> allInput,
    _AppointmentMode mode,
  ) {
    // Apply user filters (clinic + date range) before the past/today/future
    // bucket filter. Both are inclusive bounds; dates are compared as
    // ISO strings since AppointmentModel.date is already 'yyyy-MM-dd'.
    final df = DateFormat('yyyy-MM-dd');
    final startStr =
        _filterStart == null ? null : df.format(_filterStart!);
    final endStr = _filterEnd == null ? null : df.format(_filterEnd!);
    final all = allInput.where((a) {
      if (_filterClinicId != null && a.clinicId != _filterClinicId) {
        return false;
      }
      final d = a.date ?? '';
      if (startStr != null && (d.isEmpty || d.compareTo(startStr) < 0)) {
        return false;
      }
      if (endStr != null && (d.isEmpty || d.compareTo(endStr) > 0)) {
        return false;
      }
      return true;
    }).toList();

    final today = _todayString();
    final now = DateTime.now();
    int ascCompare(AppointmentModel x, AppointmentModel y) {
      final cd = (x.date ?? '').compareTo(y.date ?? '');
      if (cd != 0) return cd;
      return (x.timeSlot ?? '').compareTo(y.timeSlot ?? '');
    }

    switch (mode) {
      case _AppointmentMode.today:
        final list = all.where((a) {
          if ((a.date ?? '') != today) return false;
          final end = _appointmentEnd(a);
          if (end == null) return true;
          return end.isAfter(now);
        }).toList();
        list.sort(ascCompare);
        return list;
      case _AppointmentMode.past:
        final list = all.where((a) {
          final d = a.date ?? '';
          if (d.isEmpty) return false;
          if (d.compareTo(today) < 0) return true;
          if (d == today) {
            final end = _appointmentEnd(a);
            if (end == null) return false;
            return !end.isAfter(now);
          }
          return false;
        }).toList();
        list.sort((a, b) => ascCompare(b, a));
        return list;
      case _AppointmentMode.future:
        final list = all
            .where((a) => (a.date ?? '').compareTo(today) > 0)
            .toList();
        list.sort(ascCompare);
        return list;
    }
  }
}

enum _AppointmentMode { past, today, future }

// =============================================================================
// Clinic card — collapsed shows photo + name + address; tap to expand and
// lazy-load doctors registered in that clinic.
// =============================================================================

class _ClinicExpandableCard extends StatefulWidget {
  final ClinicModel clinic;
  const _ClinicExpandableCard({required this.clinic});

  @override
  State<_ClinicExpandableCard> createState() => _ClinicExpandableCardState();
}

class _ClinicExpandableCardState extends State<_ClinicExpandableCard> {
  bool _loadingDoctors = false;
  bool _expanded = false;
  List<Map<String, dynamic>> _doctors = [];

  Future<void> _ensureLoaded() async {
    if (_doctors.isNotEmpty || _loadingDoctors) return;
    setState(() => _loadingDoctors = true);
    final cid = widget.clinic.id;
    if (cid == null) {
      setState(() => _loadingDoctors = false);
      return;
    }
    // Direct Dio fetch because the shared GetService.getReq helper expects
    // the legacy `response: 200` envelope, but get_clinic_doctors returns
    // the modern `status: true` shape — the helper would drop our payload.
    final url = '${ApiContents.getClinicDoctorsUrl}?clinic_id=$cid';
    List<Map<String, dynamic>> list = const [];
    try {
      final dio = Dio(BaseOptions(
        headers: {
          'x-api-key': AppConstants.apiKey,
          'Accept': 'application/json',
        },
      ));
      final response = await dio.get(url);
      final raw = response.data;
      final json = raw is String ? jsonDecode(raw) : raw;
      if (json is Map && json['data'] is List) {
        list = (json['data'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else if (json is List) {
        list = json
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('clinic doctors fetch failed: $e');
      }
    }
    if (!mounted) return;
    setState(() {
      _doctors = list;
      _loadingDoctors = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.clinic;
    final imageUrl = c.image;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        onExpansionChanged: (open) {
          setState(() => _expanded = open);
          if (open) _ensureLoaded();
        },
        initiallyExpanded: _expanded,
        leading: SizedBox(
          width: 56,
          height: 56,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: hasImage
                ? ImageBoxFillWidget(
                    imageUrl: '${ApiContents.imageUrl}/$imageUrl',
                  )
                : Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.local_hospital, size: 30),
                  ),
          ),
        ),
        title: Text(
          c.title ?? '#${c.id}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: c.address == null || c.address!.isEmpty
            ? null
            : Text(
                c.address!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
        children: [
          if (_loadingDoctors)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_doctors.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  "no_doctor_found".tr,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            )
          else
            ..._doctors.map(_buildDoctorTile),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildDoctorTile(Map<String, dynamic> doctor) =>
      _doctorTile(doctor, widget.clinic.id?.toString());
}

/// Shared builder for doctor list entries used by both the multi-clinic
/// ExpansionTile flow and the single-clinic flat flow. When [wrapInCard] is
/// true the tile is wrapped in its own Card — useful when each tile lives
/// directly inside a ListView (no parent Card to provide separation).
Widget _doctorTile(
  Map<String, dynamic> doctor,
  String? clinicId, {
  bool wrapInCard = false,
}) {
  final docId = doctor['doctor_id']?.toString() ?? '';
  final name = (doctor['doctor_name'] ?? '').toString().trim().isEmpty
      ? "${doctor['f_name'] ?? ''} ${doctor['l_name'] ?? ''}".trim()
      : doctor['doctor_name']?.toString() ?? '';
  final image = doctor['doctor_image'] ?? doctor['image'];
  final specialization = doctor['doctor_specialization'] ??
      doctor['specialization'] ??
      '';
  final hasImage = image != null && image.toString().isNotEmpty;

  final tile = ListTile(
    onTap: docId.isEmpty || docId == 'null'
        ? null
        : () {
            Get.toNamed(
              RouteHelper.getDoctorsDetailsPageRoute(
                doctId: docId,
                clinicId: clinicId,
              ),
            );
          },
    leading: SizedBox(
      width: 48,
      height: 48,
      child: ClipOval(
        child: hasImage
            ? ImageBoxFillWidget(
                imageUrl: '${ApiContents.imageUrl}/$image',
              )
            : Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.person, size: 28),
              ),
      ),
    ),
    title: Text(
      name.isEmpty ? '#$docId' : name,
      style: const TextStyle(fontWeight: FontWeight.w500),
    ),
    subtitle: Text(
      specialization.toString(),
      style: const TextStyle(fontSize: 12),
    ),
    trailing: const Icon(Icons.chevron_right),
  );

  if (!wrapInCard) return tile;
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 4),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    clipBehavior: Clip.antiAlias,
    child: tile,
  );
}

/// Booking layout used when the deployment exposes a single clinic. Renders
/// the clinic info as a passive card on top, then the full doctor list as a
/// flat list of cards (no ExpansionTile, no collapse toggle).
class _SingleClinicView extends StatefulWidget {
  final ClinicModel clinic;
  const _SingleClinicView({required this.clinic});

  @override
  State<_SingleClinicView> createState() => _SingleClinicViewState();
}

class _SingleClinicViewState extends State<_SingleClinicView> {
  bool _loading = true;
  List<Map<String, dynamic>> _doctors = const [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final cid = widget.clinic.id;
    if (cid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final url = '${ApiContents.getClinicDoctorsUrl}?clinic_id=$cid';
    List<Map<String, dynamic>> list = const [];
    try {
      final dio = Dio(BaseOptions(
        headers: {
          'x-api-key': AppConstants.apiKey,
          'Accept': 'application/json',
        },
      ));
      final response = await dio.get(url);
      final raw = response.data;
      final json = raw is String ? jsonDecode(raw) : raw;
      if (json is Map && json['data'] is List) {
        list = (json['data'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else if (json is List) {
        list = json
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('single-clinic doctors fetch failed: $e');
    }
    if (!mounted) return;
    setState(() {
      _doctors = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.clinic;
    final imageUrl = c.image;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final clinicId = c.id?.toString();

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: hasImage
                        ? ImageBoxFillWidget(
                            imageUrl: '${ApiContents.imageUrl}/$imageUrl',
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child:
                                const Icon(Icons.local_hospital, size: 30),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.title ?? '#${c.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (c.address != null && c.address!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            c.address!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_doctors.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                "no_doctor_found".tr,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
        else
          ..._doctors
              .map((d) => _doctorTile(d, clinicId, wrapInCard: true)),
      ],
    );
  }
}
