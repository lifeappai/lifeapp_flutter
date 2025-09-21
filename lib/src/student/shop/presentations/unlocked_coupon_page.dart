import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../common/helper/color_code.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

class UnlockCouponPage extends StatefulWidget {

  final String? url;
  final String? title;
  final String? coin;

  const UnlockCouponPage({Key? key,
     this.url,
     this.title,
     this.coin,
  }) : super(key: key);

  @override
  State<UnlockCouponPage> createState() => _UnlockCouponPageState();
}

class _UnlockCouponPageState extends State<UnlockCouponPage> {

  @override
  void initState() {
    super.initState();
    MixpanelService.track('Redeemed Product Details Page Opened', properties: {
      'product_title': widget.title,
      'redeemed_coins': widget.coin,
    });
  }



  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width-MediaQuery.of(context).padding.right-MediaQuery.of(context).padding.left;
    return Scaffold(
      body: _body(height: height,width: width),
    );
  }

  Widget _body({height,width}) => Stack(
    children: [
      Lottie.asset("assets/lottie/comic_new.json",
        repeat: true,
        height: height,
        fit: BoxFit.fill,
      ),
      SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          height: height,
          width: width,
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                const Text(
                  "CONGRATULATIONS\nCoupon\nUnlocked!",
                  style: TextStyle(
                    color: ColorCode.buttonColor,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    "https://lifeappmedia.blr1.digitaloceanspaces.com/${widget.url!}",
                    height: MediaQuery.of(context).size.height * .3,
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  widget.title ?? "",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "You have successfully purchased this coupon. Once we verify your details, we’ll share the voucher link in the Notification box.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w400
                    ,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: MediaQuery.of(context).size.width * .8,
                  padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.black),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/images/coin.png",
                        height: 25,
                      ),
                      Text(
                        "${widget.coin!} coins used!",
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Container(
                    height: 45,
                    width: MediaQuery.of(context).size.width * .8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.white,
                    ),
                    child: const Center(
                      child: Text(
                        "back",
                        style: TextStyle(
                          color: ColorCode.buttonColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        )
      ),
    ],
  );
}
