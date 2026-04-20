import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:qr_bar_code/qr/src/qr_code.dart';
import 'package:star_rating/star_rating.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_conference/video_conference.dart';

import '../bancard/bancard_appointment_payment_provider.dart';
import '../bancard/medicare_client_payment_gateway_page.dart';
import '../controller/appointment_cancel_req_controller.dart';
import '../controller/prescription_controller.dart';
import '../helpers/date_time_helper.dart';
import '../helpers/post_req_helper.dart';
import '../helpers/route_helper.dart';
import '../helpers/theme_helper.dart';
import '../model/appointment_cancellation_model.dart';
import '../model/appointment_model.dart';
import '../model/clinic_model.dart';
import '../model/configuration_model.dart';
import '../model/invoice_model.dart';
import '../model/prescription_model.dart';
import '../pages/patient_file_page.dart';
import '../services/SocketService.dart';
import '../services/appointment_cancellation_service.dart';
import '../services/appointment_checkin_service.dart';
import '../services/appointment_service.dart';
import '../services/appointment_socket_service.dart';
import '../services/clinic_service.dart';
import '../services/configuration_service.dart';
import '../services/doctor_service.dart';
import '../services/invoice_service.dart';
import '../services/patient_files_service.dart';
import '../services/user_service.dart';
import '../utilities/api_content.dart';
import '../utilities/colors_constant.dart';
import '../utilities/image_constants.dart';
import '../utilities/socket_config.dart';
import '../video/user_video_join_data_source.dart';
import '../widget/app_bar_widget.dart';
import '../widget/button_widget.dart';
import '../widget/image_box_widget.dart';
import '../widget/loading_Indicator_widget.dart';
import '../widget/toast_message.dart';
import 'package:udemy_core/udemy_core.dart';

class AppointmentDetailsPage extends StatefulWidget {
  final String? appId;
  const AppointmentDetailsPage({super.key, this.appId});

  @override
  State<AppointmentDetailsPage> createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  bool _isLoading = false;
  bool _isRetryPaymentLoading = false;

  AppointmentModel? appointmentModel;
  List<InvoiceModel> invoiceModelList = [];

  final AppointmentCancellationController _appointmentCancellationController =
  AppointmentCancellationController();
  final PrescriptionController _prescriptionController =
  PrescriptionController();

  final ScrollController _scrollController = ScrollController();
  final TextEditingController textEditingController = TextEditingController();

  double _rating = 4;
  int? _queueNumber;
  bool _isLoadingQueue = false;
  String? clinicLat;
  String? clinicLng;
  String? email;
  String? phone;
  String? whatsapp;
  String? ambulancePhone;
  int? _joinPollCountdownSeconds;
  bool patientFileAvailable = false;
  ClinicModel? clinicModel;


  final PaymentsProvider paymentsProvider = PaymentsProvider();
  final BancardAppointmentPaymentProvider bancardAppointmentPaymentProvider =
  BancardAppointmentPaymentProvider();

  Timer? _videoTimer;
  int _videoRemainingSeconds = 0;
  bool _videoLoading = false;
  bool _doctorJoined = false;
  bool _socketReady = false;
  String? _liveMeetingLink;
  String? _liveMeetingId;
  String? _liveVideoProvider;
  Timer? _joinRefreshTimer;
  bool _waitingForDoctor = false;
  String? _waitingMessage;
  bool _socketConnected = false;
  bool _refreshingJoin = false;
  AppointmentSocketService? _appointmentSocket;

  Timer? _joinPollCountdownTimer;
  Timer? _dynamicJoinTimer;

  void _stopDynamicJoinTimer() {
    _dynamicJoinTimer?.cancel();
    _dynamicJoinTimer = null;
  }
  @override
  void initState()  {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await getAndSetData();

      _appointmentCancellationController.getData(
        appointmentId: widget.appId ?? "-1",
      );
      _prescriptionController.getData(
        appointmentId: widget.appId ?? "-1",
      );
      _startJoinRefreshTimer();
    });

  }
  Duration _getJoinPollInterval() {
    final remaining = appointmentModel?.videoJoinSecondsRemaining ?? 0;

    if (remaining > 300) {
      return const Duration(minutes: 2);
    }

    if (remaining > 120) {
      return const Duration(minutes: 1);
    }

    return const Duration(seconds: 30);
  }
  void _scheduleNextJoinCheck() {
    _stopDynamicJoinTimer();

    if (!mounted) return;
    if (appointmentModel == null) return;
    if (!(appointmentModel?.isVideoConsult ?? false)) return;

    final interval = _getJoinPollInterval();

    setState(() {
      _joinPollCountdownSeconds = interval.inSeconds;
    });

    _startJoinPollCountdown(seconds: interval.inSeconds);

    _dynamicJoinTimer = Timer(interval, () async {
      await _refreshJoinData();

      if (!mounted) return;

      final hasGoogleLink =
          _isGoogleMeetProvider && _effectiveMeetingLink.isNotEmpty;

      if (hasGoogleLink) {
        _stopWaitingRealtime();
        return;
      }

      _scheduleNextJoinCheck();
    });
  }
  void _startJoinPollCountdown({required int seconds}) {
    _joinPollCountdownTimer?.cancel();

    if (!mounted) return;

    setState(() {
      _joinPollCountdownSeconds = seconds;
    });

    _joinPollCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_joinPollCountdownSeconds!= null && _joinPollCountdownSeconds! <= 0) {
        timer.cancel();
        return;
      }

      setState(() {
        if(_joinPollCountdownSeconds != null) _joinPollCountdownSeconds = _joinPollCountdownSeconds!-1;
      });
    });
  }
  void _initAppointmentSocket() {
    final id = appointmentModel?.id;
    if (id == null || id <= 0) return;

    _appointmentSocket?.disconnect();
    _appointmentSocket = null;

    _appointmentSocket = AppointmentSocketService(
      appointmentId: id,
      onConnectionStateChange: (current, previous) {
        if (!mounted) return;

        setState(() {
          _socketConnected = current.toUpperCase().contains('CONNECTED');
        });
      },
      onEvent: (payload) async {
        if (!mounted) return;

        setState(() {
          _doctorJoined = true;
          _liveMeetingLink = payload['meeting_link']?.toString();
          _liveMeetingId = payload['meeting_id']?.toString();
          _liveVideoProvider = payload['video_provider']?.toString();
          _waitingForDoctor = false;
          _waitingMessage = null;
        });

        final provider = (_liveVideoProvider ?? '').toLowerCase();
        final link = (_liveMeetingLink ?? '').trim();

        if (provider == 'google' && link.isNotEmpty) {

          final uri = Uri.tryParse(link);
          if (uri != null) {
            _stopWaitingRealtime();
            debugPrint('OPENING_MEET_FROM_SOCKET');
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            return;
          }
        }

        await _refreshJoinData();
      },
      onError: (message, code, exception) {
        if (!mounted) return;

        setState(() {
          _socketConnected = false;
        });
      },
    );

    _appointmentSocket!.connect(
      apiKey: ApiContents.pusherApiKey,
      cluster: ApiContents.pusherCluster,
    ).catchError((error) {
      if (!mounted) return;

      setState(() {
        _socketConnected = false;
      });
    });
  }
  Future<void> _manualRefreshJoinData() async {
    if (_refreshingJoin) return;

    setState(() {
      _refreshingJoin = true;
    });

    try {
      await getAndSetData();
      await _refreshJoinData();

      final hasGoogleLink =
          _isGoogleMeetProvider && _effectiveMeetingLink.isNotEmpty;

      if (!hasGoogleLink) {
        _startJoinRefreshTimer();
      }
    } finally {
      if (mounted) {
        setState(() {
          _refreshingJoin = false;
        });
      }
    }
  }
  @override
  void dispose() {
    _joinRefreshTimer?.cancel();
    _appointmentSocket?.disconnect();
    _joinPollCountdownTimer?.cancel();
    _videoTimer?.cancel();
    _scrollController.dispose();
    textEditingController.dispose();
    final appointmentId = appointmentModel?.id;
    if (appointmentId != null) {
      SocketService.instance.unlisten(
        channelName: 'appointment-video.$appointmentId',
        eventName: 'doctor.joined',
      );
      SocketService.instance.unsubscribeFromPublicChannel(
        channelName: 'appointment-video.$appointmentId',
      );
    }
    super.dispose();
  }
  void _stopWaitingRealtime() {
    _joinRefreshTimer?.cancel();
    _joinRefreshTimer = null;

    _joinPollCountdownTimer?.cancel();
    _joinPollCountdownTimer = null;

    _appointmentSocket?.disconnect();
    _appointmentSocket = null;

    if (mounted) {
      setState(() {
        _socketConnected = false;
        _waitingForDoctor = false;
        _waitingMessage = null;
        _joinPollCountdownSeconds = 0;
      });
    }
  }

  void _startJoinRefreshTimer() {
    _scheduleNextJoinCheck();
  }

  Future<void> _refreshJoinData() async {
    if (_refreshingJoin) return;

    final appointmentId = appointmentModel?.id;
    if (appointmentId == null || appointmentId <= 0) return;

    _refreshingJoin = true;

    try {
      final res = await AppointmentService.getVideoJoinData(
        appointmentId: appointmentId,
      );

      debugPrint('refreshJoinData res: $res');

      if (!mounted || res == null || res is! Map) return;

      final data = res['data'] is Map
          ? Map<String, dynamic>.from(res['data'] as Map)
          : <String, dynamic>{};

      setState(() {
        _doctorJoined = res['doctor_joined'] == true;
        _waitingForDoctor = res['waiting_for_doctor'] == true;
        _waitingMessage = res['message']?.toString();
        _liveMeetingLink = data['meeting_link']?.toString();
        _liveMeetingId = data['meeting_id']?.toString();
        _liveVideoProvider =
            data['video_provider']?.toString() ?? data['provider']?.toString();
      });

      debugPrint('AFTER setState doctorJoined=$_doctorJoined');
      debugPrint('AFTER setState liveProvider=$_liveVideoProvider');
      debugPrint('AFTER setState liveLink=$_liveMeetingLink');

      final provider = (_liveVideoProvider ?? '').toLowerCase();
      final link = (_liveMeetingLink ?? '').trim();

      if (provider == 'google' && link.isNotEmpty) {
        _stopWaitingRealtime();
        final uri = Uri.tryParse(link);
        if (uri != null) {
          debugPrint('OPENING_MEET_FROM_POLL');
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('_refreshJoinData error: $e');
    } finally {
      _refreshingJoin = false;
    }
  }

  String get _effectiveVideoProvider =>
      (_liveVideoProvider ??
          appointmentModel?.videoProvider ??
          '')
          .toString()
          .toLowerCase();

  String get _effectiveMeetingLink =>
      (_liveMeetingLink ??
          appointmentModel?.meetingLink ??
          '')
          .toString()
          .trim();

  bool get _isGoogleMeetProvider {
    final raw = _effectiveVideoProvider;
    return raw == 'google' ||
        raw == 'google_meet' ||
        raw == 'googlemeet' ||
        raw == 'meet';
  }
  bool get _isAppointmentPaid {
    final String paymentStatus =
    (appointmentModel?.paymentStatus ?? '').toLowerCase().trim();
    return paymentStatus == 'paid';
  }

  bool get _isAppointmentPendingPayment {
    final String paymentStatus =
    (appointmentModel?.paymentStatus ?? '').toLowerCase().trim();

    if (paymentStatus == 'paid') return false;
    if (paymentStatus == 'pending') return true;
    if (paymentStatus == 'unpaid') return true;
    if (paymentStatus.isEmpty) return true;

    return true;
  }

  bool get _canRetryPayment {
    if (appointmentModel == null) return false;
    final String status = (appointmentModel?.status ?? '').trim();
    if (status == 'Cancelled' || status == 'Rejected') return false;
    return _isAppointmentPendingPayment;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResources.bgColor,
      appBar: IAppBar.commonAppBar(title: "appointment".tr,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                _joinPollCountdownSeconds !=null && _joinPollCountdownSeconds! > 0
                    ? 'Poll ${_formatPollCountdown(_joinPollCountdownSeconds!)}'
                    : 'Poll --',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: _socketConnected ? 'Socket conectado' : 'Socket desconectado',
            onPressed: () {
              IToastMsg.showMessage(
                _socketConnected ? 'Socket conectado' : 'Socket desconectado',
              );
            },
            icon: Icon(
              Icons.circle,
              color: _socketConnected ? Colors.green : Colors.grey,
              size: 16,
            ),
          ),
          IconButton(
            tooltip: 'Refrescar estado de videollamada',
            onPressed: _refreshingJoin ? null : _manualRefreshJoinData,
            icon: _refreshingJoin
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.refresh),
          ),
        ],
      ),

      body: _isLoading || appointmentModel == null
          ? const ILoadingIndicatorWidget()
          : _buildBody(),
    );
  }
  String _formatPollCountdown(int seconds) {
    if (seconds <= 0) return '0s';
    final mm = (seconds ~/ 60).toString();
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '${mm}m ${ss}s';
  }

  Widget _buildBody() {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(5),
      children: [
        buildOpDetails(),
        const SizedBox(height: 3),
        if (_canRetryPayment) _buildRetryPaymentCard(),
        if (_canRetryPayment) const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.only(bottom: 0),
          child: _buildPrescriptionListBox(),
        ),
        patientFileAvailable
            ? Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildFileBox(),
        )
            : Container(),
        _buildClinicListTile(),
        const SizedBox(height: 3),
        _buildPaymentCard(),
        appointmentModel?.status == "Visited" ||
            appointmentModel?.status == "Completed"
            ? _buildReviewBox()
            : Container(),
        const SizedBox(height: 3),
        appointmentModel?.status == "Visited" ||
            appointmentModel?.status == "Completed"
            ? Container()
            : _buildCancellationBox(),
        const SizedBox(height: 0),
        appointmentModel?.currentCancelReqStatus == null
            ? Container()
            : _buildCancellationReqListBox(),
      ],
    );
  }

  Future<void> getAndSetData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appointmentData =
      await AppointmentService.getDataById(appId: widget.appId);
      if (mounted) {
        setState(() {
          appointmentModel = appointmentData;
          _syncVideoState();
        });
      } else {
        appointmentModel = appointmentData;
        _syncVideoState();
      }

      if (!_socketReady && appointmentModel?.id != null) {
        _initAppointmentSocket();
      }

      final configRes =
      await ConfigurationService.getDataByGroupName("Basic");
      if (configRes != null) {
        for (var e in configRes) {
          if (e.idName == "clinic_location_latitude") {
            clinicLat = e.value;
          }
          if (e.idName == "clinic_location_longitude") {
            clinicLng = e.value;
          }
          if (e.idName == "whatsapp") {
            whatsapp = e.value;
          }
          if (e.idName == "phone") {
            phone = e.value;
          }
          if (e.idName == "email") {
            email = e.value;
          }
          if (e.idName == "ambulance_phone") {
            ambulancePhone = e.value;
          }
        }
      }

      final patientFile = await PatientFilesService.getDataByPatientId(
        appointmentModel?.patientId.toString() ?? "",
      );
      if (patientFile != null && patientFile.isNotEmpty) {
        patientFileAvailable = true;
      }

      final invoiceData = await InvoiceService.getDataByAppId(widget.appId);
      invoiceModelList = invoiceData ?? [];

      await getAndSetQueue();

      if (appointmentModel?.clinicId != null) {
        clinicModel = await ClinicService.getDataById(
          clinicId: appointmentModel?.clinicId.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _syncVideoState() {
    _videoTimer?.cancel();

    if (appointmentModel == null) return;
    if (!(appointmentModel?.isVideoConsult ?? false)) return;

    // Do not overwrite live values already fetched from /video/join-data.
    _liveMeetingLink ??= appointmentModel?.meetingLink;
    _liveMeetingId ??= appointmentModel?.meetingId;
    _liveVideoProvider ??= appointmentModel?.videoProvider;

    if ((_liveMeetingLink ?? '').isNotEmpty) {
      _doctorJoined = true;
    } else {
      _doctorJoined =
          _doctorJoined || (appointmentModel?.doctorJoinedAt != null);
    }

    _videoRemainingSeconds =
        appointmentModel?.videoJoinSecondsRemaining ?? 0;

    if ((appointmentModel?.mustPayFirst ?? false) ||
        (appointmentModel?.paymentStatus != 'Paid')) {
      return;
    }

    if ((appointmentModel?.canJoinVideo ?? false) ||
        _videoRemainingSeconds <= 0) {
      _videoRemainingSeconds = 0;
      return;
    }

    _videoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_videoRemainingSeconds <= 0) {
        timer.cancel();
        setState(() {
          _videoRemainingSeconds = 0;
        });
        return;
      }
      setState(() {
        _videoRemainingSeconds--;
      });
    });
  }

  String _formatVideoCountdown(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${secs.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }
  String _formatJoinCloseTime() {
    final int joinClosesAt = appointmentModel?.videoJoinClosesAt ?? 0;
    if (joinClosesAt <= 0) return '--:--';

    final date = DateTime.fromMillisecondsSinceEpoch(joinClosesAt * 1000);
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _handlePatientVideoJoin() async {
    setState(() {
      _videoLoading = true;
    });

    try {
      if (_isGoogleMeetProvider) {
        final link = _effectiveMeetingLink.trim();

        if (link.isNotEmpty) {
          final uri = Uri.tryParse(link);
          if (uri == null) {
            IToastMsg.showMessage('El enlace no es válido');
            return;
          }

          final ok = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );

          if (!ok) {
            IToastMsg.showMessage('No se pudo abrir Google Meet');
          }
          return;
        }

        setState(() {
          _waitingForDoctor = true;
          _waitingMessage = 'Esperando al doctor para abrir la sala';
        });

        await _refreshJoinData();
        _startJoinRefreshTimer();
        return;
      }

      final user = await UserService.getDataById();
      final int currentUserId = int.tryParse(user?.id?.toString() ?? '') ?? -1;

      if (!mounted) return;

      final service = VideoConferenceService(UserVideoJoinDataSource());

      await service.openForAppointment(
        context: context,
        appointmentId: appointmentModel?.id ?? 0,
        userId: currentUserId,
        isDoctor: false,
        title: 'appointmentDetails.videoConsultation'.tr,
      );
    } catch (e) {
      IToastMsg.showMessage('No se pudo abrir la videollamada');
    } finally {
      if (mounted) {
        setState(() {
          _videoLoading = false;
        });
      }
    }
  }

  Widget _buildVideoConsultAction() {
    final hasGoogleLink =
        _isGoogleMeetProvider && _effectiveMeetingLink.isNotEmpty;
    debugPrint('doctorJoined=$_doctorJoined');
    debugPrint('liveProvider=$_liveVideoProvider');
    debugPrint('liveLink=$_liveMeetingLink');
    debugPrint('effectiveProvider=$_effectiveVideoProvider');
    debugPrint('effectiveLink=$_effectiveMeetingLink');

    if (hasGoogleLink) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
        onPressed: _videoLoading ? null : _handlePatientVideoJoin,
        child: Text(
          _videoLoading
              ? 'appointmentDetails.connecting'.tr
              : 'appointmentDetails.joinVideo'.tr,
          style: const TextStyle(fontSize: 12, color: Colors.white),
        ),
      );
    }

    if (_isGoogleMeetProvider && !_doctorJoined) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _waitingForDoctor ? Colors.orange : Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
        onPressed: _videoLoading ? null : _handlePatientVideoJoin,
        child: Text(
          _videoLoading
              ? 'appointmentDetails.connecting'.tr
              : (_waitingForDoctor
              ? (_waitingMessage ?? 'Esperando al doctor')
              : 'appointmentDetails.waitingDoctorJoin'.tr),
          style: const TextStyle(fontSize: 12, color: Colors.white),
        ),
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
      ),
      onPressed: _videoLoading ? null : _handlePatientVideoJoin,
      child: Text(
        _videoLoading
            ? 'appointmentDetails.connecting'.tr
            : 'appointmentDetails.joinVideo'.tr,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }

  Widget _buildRetryPaymentCard() {
    final String paymentStatusText =
        appointmentModel?.paymentStatus?.toString() ?? 'Pending';

    return Card(
      color: ColorResources.cardBgColor,
      elevation: .1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'appointmentDetails.pendingPaymentTitle'.tr,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'appointmentDetails.currentPaymentStatus'.trArgs([paymentStatusText,
              ]),
              style: const TextStyle(
                fontSize: 13,
                color: ColorResources.secondaryFontColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'appointmentDetails.retryPaymentDescription'.tr,
              style: TextStyle(
                fontSize: 13,
                color: ColorResources.secondaryFontColor,
              ),
            ),
            const SizedBox(height: 12),
            if (_isRetryPaymentLoading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: SmallButtonsWidget(
                      title: 'appointmentDetails.payNow'.tr,
                      onPressed: _retryAppointmentPayment,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Card(
      color: ColorResources.cardBgColor,
      elevation: .1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Flexible(
                  flex: 2,
                  child: Stack(
                    children: [
                      appointmentModel!.doctImage == null ||
                          appointmentModel!.doctImage == ""
                          ? const CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 30,
                        child: Icon(Icons.person, size: 40),
                      )
                          : ClipOval(
                        child: SizedBox(
                          height: 80,
                          width: 80,
                          child: CircleAvatar(
                            child: ImageBoxFillWidget(
                              imageUrl:
                              "${ApiContents.imageUrl}/${appointmentModel!.doctImage}",
                              boxFit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ),
                      const Positioned(
                        top: 5,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.green,
                            radius: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Flexible(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${appointmentModel?.doctFName ?? "--"} ${appointmentModel?.doctLName ?? "--"}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        appointmentModel?.doctSpecialization ?? "",
                        style: const TextStyle(
                          color: ColorResources.secondaryFontColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 5),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            StarRating(
                              mainAxisAlignment: MainAxisAlignment.center,
                              length: 5,
                              color: appointmentModel?.averageRating == 0
                                  ? Colors.grey
                                  : Colors.amber,
                              rating: appointmentModel?.averageRating ?? 0,
                              between: 5,
                              starSize: 15,
                              onRaitingTap: (rating) {},
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'rating_review_text'.trParams({
                                'rating':
                                '${appointmentModel?.averageRating ?? "--"}',
                                'count':
                                '${appointmentModel?.numberOfReview ?? 0}',
                              }),
                              style: const TextStyle(
                                color: ColorResources.secondaryFontColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            color: ColorResources.iconColor,
                            size: 15,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'appointments_done'.trParams({
                              'count':
                              '${appointmentModel?.totalAppointmentDone ?? 0}',
                            }),
                            style: const TextStyle(
                              color: ColorResources.secondaryFontColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget buildOpDetails() {
    return Card(
      color: ColorResources.cardBgColor,
      elevation: .1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(),
            const SizedBox(height: 10),
            appointmentModel?.type != "OPD" ||
                appointmentModel?.status != "Confirmed"
                ? Container()
                : _queueNumber == null
                ? GestureDetector(
              onTap: () {
                openBoxToCheckIn();
              },
              child: Card(
                color: Colors.green,
                elevation: .1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "check_in".tr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.login_outlined,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            )
                : Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: _isLoadingQueue
                  ? const ILoadingIndicatorWidget()
                  : GestureDetector(
                onTap: () {
                  getAndSetQueue();
                },
                child: Card(
                  color: Colors.green,
                  elevation: .1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "queue_number_value".trParams({
                            "number": _queueNumber.toString(),
                          }),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.refresh,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "appointment_id".trParams({"id": widget.appId ?? "--"}),
                  style: const TextStyle(
                    color: ColorResources.secondaryFontColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 5),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: appointmentModel!.status == "Pending"
                          ? _statusIndicator(Colors.yellowAccent)
                          : appointmentModel!.status == "Rescheduled"
                          ? _statusIndicator(Colors.orangeAccent)
                          : appointmentModel!.status == "Rejected"
                          ? _statusIndicator(Colors.red)
                          : appointmentModel!.status == "Confirmed"
                          ? _statusIndicator(Colors.green)
                          : appointmentModel!.status ==
                          "Completed"
                          ? _statusIndicator(Colors.green)
                          : Container(),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(5, 0, 10, 0),
                      child: Text(
                        (appointmentModel!.status ?? "--").tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "patient_name".trParams({
                "name":
                "${appointmentModel!.pFName ?? "--"} ${appointmentModel!.pLName ?? "--"} #${appointmentModel?.patientId ?? "--"}",
              }),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "MRN #${appointmentModel?.patientMRN ?? "--"}",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        (appointmentModel!.type ?? "--").tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildVideoConsultAction(),
                  ],
                ),
                if (appointmentModel?.type == "Video Consultant")
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'appointmentDetails.autoCloseAt'.trArgs([_formatJoinCloseTime(),
                      ]),
                      style: const TextStyle(
                        fontSize: 12,
                        color: ColorResources.secondaryFontColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (_waitingForDoctor) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text(
                      _waitingMessage ?? 'Esperando al doctor para abrir la sala...',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "date".tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                      ),
                      Card(
                        color: ColorResources.cardBgColor,
                        elevation: .1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: ListTile(
                          title: Text(
                            DateTimeHelper.getDataFormat(
                              appointmentModel?.date ?? "",
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 13,
                            ),
                          ),
                          trailing: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            color: Colors.black,
                            child: const Padding(
                              padding: EdgeInsets.all(3.0),
                              child: Icon(
                                Icons.calendar_month,
                                color: Colors.white,
                                size: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "time".tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                      ),
                      Card(
                        color: ColorResources.cardBgColor,
                        elevation: .1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: ListTile(
                          title: Text(
                            DateTimeHelper.convertTo12HourFormat(
                              appointmentModel?.timeSlot ?? "",
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 13,
                            ),
                          ),
                          trailing: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            color: Colors.black,
                            child: const Padding(
                              padding: EdgeInsets.all(3.0),
                              child: Icon(
                                Icons.watch_later,
                                size: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildPaymentSummarySection(),
            const SizedBox(height: 10),
            SmallButtonsWidget(
              title: "rebook".tr,
              onPressed: () {
                if (appointmentModel!.doctorId != null) {
                  Get.back();
                  Get.toNamed(
                    RouteHelper.getDoctorsDetailsPageRoute(
                      doctId: appointmentModel!.doctorId!.toString(),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
  Widget _buildPaymentSummarySection() {
    final String paymentStatus =
        appointmentModel?.paymentStatus?.toString() ?? '--';
    final String paymentMethod =
        appointmentModel?.paymentMethod?.toString() ?? '--';
    final String paymentReference =
        appointmentModel?.paymentReference?.toString() ?? '--';

    debugPrint('paymentStatus $paymentStatus');
    debugPrint('paymentMethod $paymentMethod');
    debugPrint('paymentReference $paymentReference');


    return Card(
      color: ColorResources.cardBgColor,
      elevation: .05,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'appointmentDetails.paymentSummaryTitle'.tr,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'appointmentDetails.paymentSummaryStatus'.trArgs([
                paymentStatus.tr],),
            ),
            Text(
              'appointmentDetails.paymentSummaryMethod'.trArgs([
                paymentMethod,
              ],),
            ),
            if (paymentReference != '--')
              Text(
                'appointmentDetails.paymentSummaryReference'.trArgs([paymentReference
                ],),
              ),
          ],
        ),
      ),
    );
  }


  Widget _statusIndicator(Color color) {
    return CircleAvatar(radius: 4, backgroundColor: color);
  }

  Widget _buildPaymentCard() {
    return Card(
      color: ColorResources.cardBgColor,
      elevation: .1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: invoiceModelList.length,
        itemBuilder: (context, index) {
          InvoiceModel? invoiceModel =
          invoiceModelList.isNotEmpty ? invoiceModelList[index] : null;
          return ListTile(
            onTap: () async {
              await launchUrl(
                Uri.parse("${ApiContents.invoiceUrl}/${invoiceModel?.id}"),
                mode: LaunchMode.externalApplication,
              );
            },
            title: Text(
              "invoice_id".trParams({
                "id": invoiceModel == null ? "--" : "${invoiceModel.id}",
              }),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            trailing: Text(
              invoiceModel == null ? "--" : (invoiceModel.status ?? "--").tr,
              style: const TextStyle(
                color: ColorResources.primaryColor,
                fontSize: 13,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      "download_invoice".tr,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.download,
                      color: Colors.green,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildClinicListTile() {
    return Card(
      elevation: .1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ListTile(
        leading: clinicModel?.image == null || clinicModel?.image == ""
            ? const SizedBox(
          height: 70,
          width: 70,
          child: Icon(Icons.image, size: 40),
        )
            : SizedBox(
          height: 70,
          width: 70,
          child: CircleAvatar(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ImageBoxFillWidget(
                imageUrl: "${ApiContents.imageUrl}/${clinicModel?.image}",
                boxFit: BoxFit.fill,
              ),
            ),
          ),
        ),
        title: Text(
          clinicModel?.title ?? "",
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          children: [
            Text(
              clinicModel?.address ?? "",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            clinicModel == null
                ? Container()
                : clinicModel?.longitude == null || clinicModel?.latitude == null
                ? Container()
                : Row(
              children: [
                Flexible(
                  child: Text(
                    "make_direction_to_clinic_location".tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final url =
                        "http://maps.google.com/maps?daddr=${clinicModel?.latitude},${clinicModel?.longitude}";
                    try {
                      await launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (e) {
                      if (kDebugMode) {
                        print(e);
                      }
                    }
                  },
                  child: const CircleAvatar(
                    radius: 15,
                    backgroundColor: ColorResources.primaryColor,
                    child: Icon(
                      FontAwesomeIcons.locationDot,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewBox() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Card(
        color: ColorResources.cardBgColor,
        elevation: .1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: ListTile(
          onTap: () {
            _openDialogBoxReview();
          },
          title: Text(
            "review".tr,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            "click_here_to_give_doctor_review".tr,
            style: const TextStyle(
              fontSize: 13,
              color: ColorResources.secondaryFontColor,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCancellationBox() {
    return Card(
      color: ColorResources.cardBgColor,
      elevation: .1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: ListTile(
        onTap: appointmentModel?.currentCancelReqStatus == null
            ? _openDialogBox
            : appointmentModel?.currentCancelReqStatus == "Initiated"
            ? _openDialogBoxDeleteReq
            : null,
        trailing: const Icon(
          Icons.arrow_right,
          color: ColorResources.btnColor,
        ),
        title: Text(
          "appointment_cancellation".tr,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            appointmentModel?.currentCancelReqStatus == null
                ? Text(
              "to_create_cancellation_request".tr,
              style: const TextStyle(
                color: ColorResources.secondaryFontColor,
                fontSize: 13,
              ),
            )
                : appointmentModel?.currentCancelReqStatus == "Initiated"
                ? Text(
              "to_delete_cancellation_request".tr,
              style: const TextStyle(
                color: ColorResources.secondaryFontColor,
                fontSize: 13,
              ),
            )
                : Container(),
            appointmentModel?.currentCancelReqStatus == null
                ? Container()
                : Text(
              "current_status_value".trParams({
                "value":
                appointmentModel?.currentCancelReqStatus ?? "--",
              }),
              style: const TextStyle(
                color: ColorResources.secondaryFontColor,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDialogBoxReview() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              title: Text(
                "doctor_review".tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "review_to_doctor_value".trParams({
                      "doctName":
                      "${appointmentModel?.doctFName ?? "--"} ${appointmentModel?.doctLName ?? "--"}",
                    }),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StarRating(
                    mainAxisAlignment: MainAxisAlignment.center,
                    length: 5,
                    color: Colors.amber,
                    rating: _rating,
                    between: 5,
                    starSize: 30,
                    onRaitingTap: (rating) {
                      setStateDialog(() {
                        _rating = rating;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: ThemeHelper().inputBoxDecorationShaddow(),
                    child: TextFormField(
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      controller: textEditingController,
                      decoration:
                      ThemeHelper().textInputDecoration('review'.tr),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorResources.btnColorRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "cancel".tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorResources.btnColorGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "submit".tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _handleToSubmitReview();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openDialogBox() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Text(
            "cancel".tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "cancel_this_appointment_box".tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorResources.btnColorGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "no".tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorResources.btnColorRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "yes".tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _handleAppointmentCanReq();
              },
            ),
          ],
        );
      },
    );
  }

  void _openDialogBoxDeleteReq() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Text(
            "delete".tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "delete_the_cancellation_request_box".tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorResources.btnColorRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "no".tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorResources.btnColorGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "yes".tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _handleAppointmentDeleteReq();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleToSubmitReview() async {
    setState(() {
      _isLoading = true;
    });

    final res = await DoctorsService.addDoctorReView(
      appointmentId: appointmentModel?.id.toString() ?? "",
      description: textEditingController.text,
      doctorId: appointmentModel?.doctorId?.toString() ?? "",
      points: _rating.toString(),
    );

    if (res != null) {
      IToastMsg.showMessage("success".tr);
      _appointmentCancellationController.getData(
        appointmentId: widget.appId ?? "-1",
      );
      getAndSetData();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _handleAppointmentCanReq() async {
    setState(() {
      _isLoading = true;
    });

    final res = await AppointmentCancellationService
        .addAppointmentCancelRequest(
      appointmentId: appointmentModel?.id.toString() ?? "",
      status: "Initiated",
    );

    if (res != null) {
      IToastMsg.showMessage("success".tr);
      _appointmentCancellationController.getData(
        appointmentId: widget.appId ?? "-1",
      );
      getAndSetData();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _handleAppointmentDeleteReq() async {
    setState(() {
      _isLoading = true;
    });

    final res = await AppointmentCancellationService.deleteReq(
      appointmentId: appointmentModel?.id.toString() ?? "",
    );

    getAndSetData();
    _appointmentCancellationController.getData(
      appointmentId: widget.appId ?? "-1",
    );

    if (res != null) {
      IToastMsg.showMessage("success".tr);
      getAndSetData();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildCancellationReqListBox() {
    return Card(
      color: ColorResources.cardBgColor,
      elevation: .1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Obx(() {
        if (!_appointmentCancellationController.isError.value) {
          if (_appointmentCancellationController.isLoading.value) {
            return const ILoadingIndicatorWidget();
          } else {
            return _appointmentCancellationController.dataList.isEmpty
                ? Container()
                : ListTile(
              title: Text(
                "cancellation_request_history".tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                itemCount:
                _appointmentCancellationController.dataList.length,
                itemBuilder: (context, index) {
                  AppointmentCancellationRedModel item =
                  _appointmentCancellationController.dataList[index];
                  return ListTile(
                    leading: Icon(
                      Icons.circle,
                      size: 10,
                      color: item.status == "Initiated"
                          ? Colors.yellow
                          : item.status == "Rejected"
                          ? Colors.red
                          : item.status == "Approved"
                          ? Colors.green
                          : item.status == "Processing"
                          ? Colors.orange
                          : Colors.grey,
                    ),
                    title: Text(
                      (item.status ?? "--").tr,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        item.notes == null
                            ? Container()
                            : Text(
                          item.notes ?? "--",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          DateTimeHelper.getDataFormat(
                            item.createdAt ?? "--",
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Divider(color: Colors.grey.shade100),
                      ],
                    ),
                  );
                },
              ),
            );
          }
        } else {
          return Container();
        }
      }),
    );
  }

  Widget _buildFileBox() {
    return Card(
      color: ColorResources.cardBgColor,
      elevation: .1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: ListTile(
        trailing: const Icon(
          Icons.arrow_right,
          color: ColorResources.iconColor,
          size: 30,
        ),
        onTap: () {
          Get.to(
                () => PatientFilePage(
              patientId: appointmentModel?.patientId.toString(),
            ),
          );
        },
        title: Text(
          "patient_files".tr,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          "click_here_to_check_the_patient_files".tr,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPrescriptionListBox() {
    return Card(
      color: ColorResources.cardBgColor,
      elevation: .1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: ListTile(
        title: Text(
          "prescription".tr,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Obx(() {
          if (!_prescriptionController.isError.value) {
            if (_prescriptionController.isLoading.value) {
              return const ILoadingIndicatorWidget();
            } else {
              return _prescriptionController.dataList.isEmpty
                  ? Text(
                "no_prescription_found".tr,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              )
                  : ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                itemCount: _prescriptionController.dataList.length,
                itemBuilder: (context, index) {
                  PrescriptionModel prescriptionModel =
                  _prescriptionController.dataList[index];
                  return ListTile(
                    trailing: const Icon(
                      Icons.download,
                      size: 20,
                      color: ColorResources.iconColor,
                    ),
                    onTap: () async {
                      if (prescriptionModel.pdfFileUrl != null &&
                          prescriptionModel.pdfFileUrl != "") {
                        await launchUrl(
                          Uri.parse(
                            "${ApiContents.imageUrl}/${prescriptionModel.pdfFileUrl}",
                          ),
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        await launchUrl(
                          Uri.parse(
                            "${ApiContents.prescriptionUrl}/${prescriptionModel.id}",
                          ),
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    title: Text(
                      "prescription_id".trParams({
                        "id": "${prescriptionModel.id ?? "--"}",
                      }),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      "click_here_to_download_prescription".tr,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  );
                },
              );
            }
          } else {
            return Container();
          }
        }),
      ),
    );
  }

  Future<void> getAndSetQueue() async {
    if (appointmentModel == null) return;

    setState(() {
      _isLoadingQueue = true;
    });

    final res = await AppointmentCheckinService.getData(
      doctId: appointmentModel!.doctorId.toString(),
      date: appointmentModel?.date ?? "",
    );

    if (res != null) {
      for (int i = 0; i < res.length; i++) {
        if (res[i].appointmentId == appointmentModel?.id) {
          _queueNumber = i + 1;
          break;
        }
      }
    } else {
      _queueNumber = null;
    }

    setState(() {
      _isLoadingQueue = false;
    });
  }

  void openBoxToCheckIn() {
    showModalBottomSheet(
      backgroundColor: ColorResources.bgColor,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setStateModal) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: ColorResources.bgColor,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20.0),
                  topLeft: Radius.circular(20.0),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 20,
                    left: 5,
                    right: 5,
                    bottom: 0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          ImageConstants.checkImageBox,
                          height: 80,
                          width: 80,
                        ),
                        const SizedBox(height: 30),
                        Text(
                          "appointment_id".trParams({"id": "${widget.appId}"}),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "appointment_type".trParams({
                            "type": appointmentModel?.type ?? "--",
                          }),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "date_checkin".trParams({
                            "date": DateTimeHelper.getDataFormat(
                              appointmentModel?.date ?? "",
                            ),
                          }),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "time_checkin".trParams({
                            "time": DateTimeHelper.convertTo12HourFormat(
                              appointmentModel?.timeSlot ?? "",
                            ),
                          }),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Divider(),
                        ),
                        QRCode(
                          size: 300,
                          data: getQrCodeData(),
                        ),
                        Text(
                          "checkin_desc".tr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String getQrCodeData() {
    final qrData = {
      "appointment_id": widget.appId,
      "date": appointmentModel?.date,
      "time": appointmentModel?.timeSlot,
    };
    return jsonEncode(qrData);
  }

  Future<void> _retryAppointmentPayment() async {
    if (appointmentModel == null) return;

    setState(() {
      _isRetryPaymentLoading = true;
    });

    try {
      final user = await UserService.getDataById();
      final int userId = int.tryParse(user?.id?.toString() ?? '') ?? -1;

      if (userId <= 0) {
        IToastMsg.showMessage("appointmentDetails.userNotFound".tr);
        setState(() {
          _isRetryPaymentLoading = false;
        });
        return;
      }

      final double amount = double.tryParse(
        appointmentModel?.totalAmount?.toString() ?? '',
      ) ??
          0;

      if (amount <= 0) {
        IToastMsg.showMessage("appointmentDetails.invalidPaymentAmount".tr);
        setState(() {
          _isRetryPaymentLoading = false;
        });
        return;
      }

      final int paymentTypeId =
      _resolvePaymentTypeIdFromAppointment(appointmentModel);

      final Map<String, dynamic>? paymentStartResponse =
      await bancardAppointmentPaymentProvider.startAppointmentPayment(
        appointmentId: int.tryParse(appointmentModel?.id.toString() ?? '') ?? 0,
        userId: userId,
        paymentTypeId: paymentTypeId,
        amount: amount,
        currency: 'PYG',
        description:
        'appointmentDetails.retryPaymentDescriptionLine'.trArgs(['${appointmentModel?.id ?? "--"}',
        ]),
      );

      print('retry paymentStart raw = $paymentStartResponse');

      if (paymentStartResponse == null) {
        IToastMsg.showMessage("appointmentDetails.paymentStartFailed".tr);
        setState(() {
          _isRetryPaymentLoading = false;
        });
        return;
      }

      final Map<String, dynamic> root = paymentStartResponse;

      final Map<String, dynamic> data =
      root['data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(root['data'])
          : root['data'] is Map
          ? Map<String, dynamic>.from(root['data'])
          : root;

      final Map<String, dynamic> paymentFlow =
      data['payment_flow'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(data['payment_flow'])
          : data['payment_flow'] is Map
          ? Map<String, dynamic>.from(data['payment_flow'])
          : <String, dynamic>{};
      final String mode = paymentFlow['mode']?.toString() ?? '';

      if (mode == 'manual_validation') {
        IToastMsg.showMessage("appointmentDetails.manualValidationPending".tr);
        await getAndSetData();
        setState(() {
          _isRetryPaymentLoading = false;
        });
        return;
      }

      if (mode == 'auto_paid') {
        IToastMsg.showMessage("appointmentDetails.paymentRecordedSuccessfully".tr);
        await getAndSetData();
        setState(() {
          _isRetryPaymentLoading = false;
        });
        return;
      }

      final String? checkoutPageUrl =
      paymentFlow['checkout_page_url']?.toString();
      final String? paymentUrl = paymentFlow['payment_url']?.toString();

      if ((checkoutPageUrl == null || checkoutPageUrl.isEmpty) &&
          (paymentUrl == null || paymentUrl.isEmpty)) {
        IToastMsg.showMessage("paymentGateway.missingPaymentUrl".tr);
        setState(() {
          _isRetryPaymentLoading = false;
        });
        return;
      }

      setState(() {
        _isRetryPaymentLoading = false;
      });

      final dynamic result = await Get.to(
            () => MedicareClientPaymentGatewayPage(),
        arguments: {
          'appointment_id': appointmentModel?.id,
          'patient_name':
          '${appointmentModel?.pFName ?? "--"} ${appointmentModel?.pLName ?? "--"}',
          'payment_amount': amount,
          'checkout_page_url': checkoutPageUrl,
          'payment_url': paymentUrl,
          'payment_id': paymentFlow['payment_id'],
          'payment_type_id': paymentFlow['payment_type_id'],
          'provider': paymentFlow['provider'],
          'provider_reference': paymentFlow['provider_reference'],
          'provider_process_id': paymentFlow['provider_process_id'],
        },
      );

      await _handleRetryGatewayResult(result);
    } catch (e) {
      if (kDebugMode) {
        print('_retryAppointmentPayment error: $e');
      }

      setState(() {
        _isRetryPaymentLoading = false;
      });

      IToastMsg.showMessage("something_went_wrong".tr);
    }
  }

  int _resolvePaymentTypeIdFromAppointment(AppointmentModel? appointment) {
    final String method =
    (appointment?.paymentMethod ?? '').toUpperCase().trim();

    if (method.contains('DEBITO')) return 7000;
    if (method.contains('QR')) return 7900;
    if (method.contains('CREDITO')) return 7500;
    if (method.contains('CLINICA')) return 1100;
    if (method.contains('TRANSFER')) return 1200;
    if (method.contains('CONVENIO')) return 2100;

    return 7500;
  }

  Future<void> _handleRetryGatewayResult(dynamic result) async {
    if (result is Map) {
      final String status =
          result['payment_gateway_status']?.toString() ?? 'unknown';

      if (status == 'success') {
        IToastMsg.showMessage("Pago realizado correctamente.");
      } else if (status == 'canceled') {
        IToastMsg.showMessage("Pago cancelado. La cita sigue pendiente.");
      } else {
        IToastMsg.showMessage("La cita sigue pendiente de pago.");
      }
    }

    await getAndSetData();
  }

  Map<String, dynamic> _parseDynamicMap(dynamic rawData) {
    if (rawData == null) return <String, dynamic>{};

    if (rawData is Map<String, dynamic>) {
      return rawData;
    }

    if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    }

    if (rawData is String) {
      try {
        final dynamic decoded = jsonDecode(rawData);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return <String, dynamic>{};
      }
    }

    return <String, dynamic>{};
  }
}