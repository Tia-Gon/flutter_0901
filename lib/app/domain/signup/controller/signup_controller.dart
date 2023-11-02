import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:simple_webapp/app/core/api/user/user_api.dart';
import 'package:simple_webapp/app/core/constants/app_route_constants.dart';
import 'package:simple_webapp/app/core/data/models/location_model.dart';
import 'package:simple_webapp/app/core/data/models/user_model.dart';
import 'package:simple_webapp/app/core/providers/services_providers.dart';
import 'package:simple_webapp/app/core/services/app_service.dart';
import 'package:simple_webapp/app/core/utils/date_utils.dart';
import 'package:simple_webapp/app/core/utils/dialog_utils.dart';
import 'package:simple_webapp/app/routes/app_router.dart';

class SignupController extends ChangeNotifier {
  SignupController(this.ref, this._appService, this._userApi);

  static final provider = ChangeNotifierProvider.autoDispose(
    (ref) {
      final appService = ref.watch(appServiceProvider);
      final userApi = ref.watch(UserApi.provider);
      return SignupController(ref, appService, userApi);
    },
  );

  final Ref ref;
  final AppService _appService;
  final UserApi _userApi;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final picker = ImagePicker();
  UserModel newUser = UserModel();
  String addressValue = '';
  List<LocationModel> searchedAddress = [];
  String addressSearchValue = '';

  // 회원가입 처리후 화면 이동
  Future<void> signup() async {
    if (formKey.currentState?.validate() ?? false) {
      _appService.loginUser = await _userApi.postUser(user: newUser);

      if ((_appService.loginUser.email).isNotEmpty) {
        await showCustomAlert(
          title: '회원 가입을 축하드립니다.',
          action: () => ref.read(AppRouter.provider).go(AppRouteConstants.main),
        );
      }
    }
  }

  // 프로필 이미지 선택 후 파일 업로드
  Future<void> setProfileImage() async {
    final pickedFile =
        await picker.pickImage(maxWidth: 800, source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = await pickedFile.readAsBytes();
      final url = await uploadFile(
          file: file,
          fileName: '${DateUtil.currentEpoch13}_${pickedFile.name}');

      if (url.isNotEmpty) {
        newUser = newUser.copyWith(profileImage: url);
      }
      notifyListeners();
    }
  }

  // AWS S3PreSignedUrl 요청 후 qkfrmqqkedms Url로 파일 업로드
  Future<String> uploadFile(
      {required Uint8List file, required String fileName}) async {
    final url = await _userApi.postUserS3PreSignedUrl(
        filename: fileName, method: 'PUT');
    final ret = await _userApi.uplaodS3PresignedUrl(
        url: url, fileName: fileName, file: file);
    return ret;
  }

  void setUserEmail(String value) => newUser = newUser.copyWith(email: value);
  void setUserName(String value) => newUser = newUser.copyWith(name: value);
  void setUserMobile(String value) => newUser = newUser.copyWith(mobile: value);
  void setAddress() {
    ref.read(AppRouter.provider).pop();
    newUser = newUser.copyWith(address: addressValue);
    notifyListeners();
  }

  void changeAddress(item) {
    addressValue = item.road_address_name;
    notifyListeners();
  }

  void cancelAddress() {
    ref.read(AppRouter.provider).pop();
    addressValue = newUser.address;
    notifyListeners();
  }

  void getAddress(String keyword) async {
    searchedAddress = await _userApi.getLocations(search: keyword);
    notifyListeners();
  }
}
