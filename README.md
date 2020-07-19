# Flutter Download Manager

* 서버로 부터 여러개의 파일을 다운로드 한다.

* 증분 다운로드를 할 수 있다.
  * 변경된 파일 또는 추가된 파일만 다운로드 가능.


## Dependencies

``` yaml
dio: ^3.0.9
hive: ^1.4.1+1
hive_flutter: ^0.3.0+2
```

* dio 로 파일 다운로드를 한다.
* hive 에 설정을 저장한다.

## 에제와 설명


* 예제)

``` dart
() async {
  DownloadManager(
    fileStampJsonUrl:
        'https://api.english-fun.com/wordpress-api-v2/php/api.php?method=englishfun.audio_file_stamp&v=2',
    downloadFolderUrl:
        'https://api.english-fun.com/wordpress-api-v2/res/englishfun/audio_3000',
    saveFolder: 'audio_3000',
    batch: 50,
    hiveBoxName: boxName,
    onProgress: (n) => print(n),
    onComplete: () => print('completed!'),
    onVerify: (re) => print('verified: $re'),
  );
}();
```

* `fileStampJsonUrl` - 파일과 file time stamp 를 가지는 JSON 파일 경로
  * 그냥 JSON 파일어도 되고, PHP 등으로 출력하는 값이어도 된다.
  * 데이터 포멧은 `{ 'filename': 12345, 'filename 2', 567890, }` 와 같이 단순히 파일 이름과 file time stamp 값을 가지면 되다.
  * 파일이 추가되면, 그냥 파일 이름과 stamp 를 추가하면 된다.
  * 파일이 변경되면, stamp 만 변경하면 된다.
  * 사용 예) 서버의 특정 폴더에 있는 파일들을 다운로드 하려 할 때, PHP 등으로 파일과 그 파일의 stamp 를 읽어서 JSON 으로 출력하면 된다.
    * 그러면 폴더에서 변경되거나 추가된 파일도 다음 다운로드 시에 다운로드가 된다.

* `downloadFolderUrl` - 파일들을 보관하고 있는 폴더의 주소. 끝에 슬래시(/)를 붙이지 않는다.
* `saveFolder` - 모바일 앱의 temporary 폴더 내에서 저장 할 경로
* `batch` - 한번에 몇 개의 파일을 다운로드 할 지 결정한다. 10개에서 50개 사이면 적당하다.
* `hiveBoxName` - file 과 file time stamp 의 정보를 저장할 hive box.
  * Hive box 를 별도로 쓰므로 여러개의 폴더로 부터 이미지를 다운로드 할 수 있다.
  * 앱 초기화를 할 때, openBox(...) Hive box 를 한번 열어주어야 한다.

* `onProgress` - 다운로드 진행 과정에서 다운로드 퍼센티지를 숫자로 리턴한다. 1, 2, 3 과 같이 int 로 받아 표시 할 수 있다.
* `onComplete` - 다운로드가 완료되면 호출되는 call back.
* `onVerify` - `fileStampJsonUrl` 에 기록된 file 들이 모두 다운로드되었는지 확인을 한다.
  * 이 함수가 null 이면, 즉, 콜백을 사용하지 않으면, 관련 루틴 자체가 실행되지 않는다.
  * 이 함수는 onComplete 가 호출 된 다음에 실행된다.
  * 이 함수는 모든 파일이 다운로드되어 더 이상 다운로드 할 것이 없어도, 실행된다. 즉, 다운로를 하지 않아도, `fileStampJsonUrl` 에 있는 file 이 모두 다운로드 되었는지 검사를 한다.
  * 모두 다운르되었으면 true, 아니면 false 가 전달된다.

## 기타

* 기본적으로 매번 다운로드를 하는데,
  * 만약, 특정 시간 내에 다운로드하는 것을 무시하려면 적절히 코딩을 하면 된다.
  * 예를 들어, 24시간 이내에 두번 다운로드 하지 않도록 하려면, 적절히 코딩을 하면 된다.
