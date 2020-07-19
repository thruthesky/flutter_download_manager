import 'package:flutter/material.dart';

class DownloadProgressBar extends StatelessWidget {
  const DownloadProgressBar({
    Key key,
    @required this.progress,
  }) : super(key: key);

  final Map<String, int> progress;

  @override
  Widget build(BuildContext context) {
    if (progress == null) return SizedBox.shrink();
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: LinearProgressIndicator(
                value: progress['percentage'] / 100,
              ),
            ),
            SizedBox(
              width: 40,
              child: Text(
                '${progress['percentage']}%',
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        if (progress['noOfFiles'] != progress['noOfFilesToDownload'])
          Row(
            children: <Widget>[
              Expanded(
                child: LinearProgressIndicator(
                  value: progress['overAllPercentage'] / 100,
                  valueColor: AlwaysStoppedAnimation(Colors.black38),
                  backgroundColor: Colors.black12,
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '${progress['overAllPercentage']}%',
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
