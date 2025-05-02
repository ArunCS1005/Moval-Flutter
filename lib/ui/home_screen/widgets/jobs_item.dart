import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:moval/api/urls.dart';
import 'package:moval/ui/home_screen/widgets/confirm_approve.dart';
import 'package:moval/ui/home_screen/widgets/job_rejected.dart';
import 'package:moval/util/routes.dart';
import 'package:moval/widget/a_text.dart';

import '../../../api/api.dart';
import '../../../util/preference.dart';
import '../../../widget/a_snackbar.dart';
import '../../util_ui/UiUtils.dart';

class JobsItem extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(dynamic)? onResponse;

  const JobsItem(this.data, {Key? key, this.onResponse}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ItemPendingJobsList();
  }
}

class _ItemPendingJobsList extends State<JobsItem> {

  bool _isShowRemark = false;
  bool _isILAApproved = false;

  @override
  Widget build(BuildContext context) {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    String platform = _data('platform');
    String role = Preference.getStr(Preference.userRole);
    return Container(
      margin: const EdgeInsets.only(
        top: 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            color: Colors.black26,
          )
        ],
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        shape: Border.all(color: Colors.transparent),
        trailing: _isPendingPage()
            ? const SizedBox()
            : const Padding(
                padding: EdgeInsets.all(2.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.more_horiz),
                  ],
                ),
              ),
        onExpansionChanged: (bool isExpanded) {
          if (_isPendingPage()) {
            _openJobsDetail();
          }
        },
        title: Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _rowDateId,
              AText(
                'Registration No. : ${_data('vehicle_reg_no')}',
                fontWeight: FontWeight.w500,
                margin: _topMargin,
              ),
              AText(
                'Contact Details',
                textColor: const Color.fromARGB(255, 10, 239, 62),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                margin: _topMargin,
              ),
              AText(
                _data('contact_person').isEmpty
                    ? '-'
                    : _data('contact_person'),
                fontWeight: FontWeight.w600,
                margin: _topMargin,
              ),
              AText(
                '+91 ${_data((platform == platformTypeMS) ? 'contact_no' : 'contact_mobile_no')}',
                fontWeight: FontWeight.w600,
                margin: _topMargin,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_data('inspection_place').isNotEmpty)
                          AText(
                            _data('inspection_place'),
                            textColor: Colors.red,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            margin: const EdgeInsets.only(top: 5, bottom: 5),
                          ),
                        _remark,
                        _remarkText,
                      ],
                    ),
                  ),
                  if (_data('job_status') == rejected)
                    InkWell(
                      onTap: _showRejectionDialog,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10, top: 10),
                        child: SvgPicture.asset(
                          'assets/images/remark-flag.svg',
                          width: 25,
                          height: 25,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        children: _isPendingPage()
            ? []
            : [
                Container(
                  color: Colors.grey.withOpacity(0.1),
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      JobItemDetailsWidget(
                        title: 'No. of Photos',
                        info: _data('no_of_photos'),
                      ),
                      JobItemDetailsWidget(
                        title: 'No. of Docs',
                        info: _data('no_of_documents'),
                      ),
                      JobItemDetailsWidget(
                        title: 'Requested By',
                        info: _data('client_name'),
                      ),
                      JobItemDetailsWidget(
                        title: 'Loss Est.',
                        info: (double.tryParse(
                                    _data('loss_estimate') as String) ??
                                0.0)
                            .toStringAsFixed(2),
                      ),
                      JobItemDetailsWidget(
                        title: 'Insurer Lib.',
                        info: (double.tryParse(
                                    _data('insurer_liability') as String) ??
                                0.0)
                            .toStringAsFixed(2),
                      ),
                      const SizedBox(
                        height: 50,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          JobItemButtonWidget(
                            imagePath: 'assets/images/eye.png',
                            onTap: _openJobsDetail,
                          ),
                          JobItemButtonWidget(
                            imagePath: 'assets/images/pdf.png',
                            badgeLabel: 'ILA',
                            onTap: () async {
                              bool isPDFLoaded = (await Navigator.pushNamed(
                                    context,
                                    Routes.pdfView,
                                    arguments: {
                                      'title': 'ILA PDF',
                                      'url': ilaPDFUrl,
                                      "type": "ilarwol",
                                      'job_id': _data('id'),
                                    },
                                  ) as bool?) ??
                                  false;
                              setState(() {
                                _isILAApproved = isPDFLoaded;
                              });
                            },
                          ),

                          JobItemButtonWidget(
                            imagePath: 'assets/images/pdf.png',
                            badgeLabel: 'WA',
                            onTap: () async {
                              await Navigator.pushNamed(
                                context,
                                Routes.pdfView,
                                arguments: {
                                  'title': 'Work Approval PDF',
                                  'url': workApprovalPDFUrl,
                                  'job_id': _data('id'),
                                },
                              );
                            },
                          ),
                          if (role != 'employee' &&
                              role != 'Branch Contact' &&
                              _data('job_status') != approved)
                            JobItemButtonWidget(
                              imagePath: 'assets/images/add_signature.png',
                              isEnabled: _isILAApproved,
                              onTap: () async {
                                bool approved = await _confirmApproveDialog();
                                if (!approved) return;

                                // Trigger a hard refresh of both pending claims and To be Approved pages
                                widget.onResponse?.call('hard_refresh');

                                // Show approval confirmation
                                ASnackBar.showSnackBar(
                                  scaffoldMessengerState,
                                  'Approved.',
                                  0,
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
      ),
    );
  }

  Future<bool> _confirmApproveDialog() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);

    bool confirmApproval = await showDialog(
      context: context,
      builder: (builder) => const ConfirmApprove(),
    );

    if (!confirmApproval) return false;

    final response = await Api(scaffoldMessengerState).approveJob(
      jobId: _data('id'),
    );

    if (response == Api.defaultError || response == Api.internetError) {
      return false;
    } else if (response == Api.authError) {
      UiUtils.authFailed(navigatorState);
      return false;
    }

    return true;
  }

  get _rowDateId => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (_data('is_offline') == 'yes')
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: CircleAvatar(
                    backgroundColor: Colors.redAccent,
                    maxRadius: 3,
                  ),
                ),
              AText(
                '# ${int.parse(_data('id')).isNegative ? 'NEW' : _data('id')}',
                fontWeight: FontWeight.w500,
              ),
            ],
          ),
          AText(
            _date(),
            fontWeight: FontWeight.w200,
            fontSize: 12,
          ),
        ],
      );

  get _remark => _data('remark').isEmpty
      ? const SizedBox()
      : InkWell(
    onTap: () => setState(() {
      _isShowRemark = !_isShowRemark;
    }),
    child: RichText(
      text: TextSpan(
        children: [
          const TextSpan(
            text: 'Remark',
            style: TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w500),
          ),
          WidgetSpan(
            child: Icon(
              _isShowRemark
                  ? Icons.keyboard_arrow_up_sharp
                  : Icons.keyboard_arrow_down_sharp,
              size: 16,
              color: const Color.fromARGB(255, 255, 154, 98),
            ),
          ),
        ],
      ),
    ),
  );

  get _remarkText => _isShowRemark
      ? AText(
    _data('remark'),
    fontSize: 12,
    fontWeight: FontWeight.w200,
  )
      : const SizedBox();

  _data(String key) => (widget.data[key] ?? '').toString();

  _date() =>
      DateFormat('dd/MM/yyyy').format(DateTime.parse(_data('created_at')));

  get _topMargin => const EdgeInsets.only(top: 5);

  updateUiUnRead() {
    setState(() {});
  }

  bool _isPendingPage() => (_data('job_status') == pending ||
      _data('job_status') == rejected);

  _openJobsDetail() async {
    widget.onResponse?.call(await Navigator.pushNamed(
        context, Routes.pendingJobs,
        arguments: widget.data));
  }

  _showRejectionDialog() => showDialog(
      context: context,
      builder: (builder) =>
          JobRejected(widget.data['id'], _data('admin_remark')));
}

class JobItemButtonWidget extends StatelessWidget {
  final String imagePath;
  final String? badgeLabel;
  final bool isEnabled;
  final void Function()? onTap;

  const JobItemButtonWidget({
    Key? key,
    required this.imagePath,
    required this.onTap,
    this.isEnabled = true,
    this.badgeLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      child: Badge(
        isLabelVisible: (badgeLabel != null),
        label: (badgeLabel == null) ? null : Text(badgeLabel!),
        child: Container(
          height: 45,
          width: 45,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xffffffff),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Image.asset(
            imagePath,
            color: (isEnabled) ? null : Colors.grey.withOpacity(0.5),
            width: 24,
            height: 24,
          ),
        ),
      ),
    );
  }
}

class JobItemDetailsWidget extends StatelessWidget {
  const JobItemDetailsWidget({
    super.key,
    required this.title,
    required this.info,
  });

  final String title;
  final String info;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AText(
            title,
            fontSize: 14,
            textColor: const Color(0xff6f6f6f),
          ),
          AText(
            info,
            fontSize: 16,
            textColor: Colors.black,
          ),
        ],
      ),
    );
  }
}
