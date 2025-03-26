
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moval/api/urls.dart';
import 'package:moval/widget/a_text.dart';

class ContactInfo extends StatelessWidget{

  final Map data;
  final String platform;

  const ContactInfo(
    this.data, {
    Key? key,
    required this.platform,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
          blurRadius: 4,
          color: Colors.black26,
        )
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _dateRow,
          const SizedBox(height: 2),
          AText(
            _data((platform == platformTypeMS) ? 'insured_name' : 'owner_name'),
          ),
          const SizedBox(height: 15),
          const AText(
            'Contact Details',
            textColor: Color.fromARGB(255, 10, 239, 62),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 2),
          AText(
            _data('contact_person').isEmpty ? '-' : _data('contact_person'),
            fontWeight: FontWeight.w600,
          ),
          AText(
            '+91 ${_data((platform == platformTypeMS) ? 'contact_no' : 'contact_mobile_no')}',
          ),
          AText(_data('address'), fontSize: 12, fontWeight: FontWeight.w300),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AText(
                      (platform == platformTypeMS)
                          ? 'Survey Place'
                          : 'Inspection Place:',
                      textColor: const Color.fromARGB(255, 10, 239, 62),
                      fontSize: 14,
                    ),
                    AText(_data(platform == platformTypeMS
                        ? 'place_survey'
                        : 'inspection_place')),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AText(
                      (platform == platformTypeMS)
                          ? 'Insurer Name'
                          : 'Requested By:',
                      textColor: const Color.fromARGB(255, 10, 239, 62),
                      fontSize: 14,
                    ),
                    AText(_data(platform == platformTypeMS
                        ? 'client_name'
                        : 'requested_by_name')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  get _dateRow => Row(
        mainAxisAlignment: (platform == platformTypeMS)
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.end,
        children: [
          if (platform == platformTypeMS)
            const AText(
              'Insured Details',
              textColor: Color.fromARGB(255, 10, 239, 62),
              fontSize: 14,
            ),
          AText(
            _date,
            textColor: Colors.black,
            fontWeight: FontWeight.w300,
            fontSize: 14,
          )
        ],
      );

  String _data(String key) => data[key] ?? '';

  String get _date => DateFormat('dd/MM/yyyy').format(
        DateTime.parse(
          _data('created_at').isEmpty
              ? '2001-01-17 00:00:00'
              : _data('created_at'),
        ),
      );
}