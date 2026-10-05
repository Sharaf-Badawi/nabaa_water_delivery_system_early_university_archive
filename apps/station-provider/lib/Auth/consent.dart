import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../InfoGathering/LocationsData.dart';
import '../InfoGathering/NamePhoneInfo.dart';

class ConsentPage extends StatefulWidget {
  final String userId;

  const ConsentPage({super.key, required this.userId});

  @override
  _ConsentPageState createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  bool isConsentGiven = false;

  // Method to save consent status in SharedPreferences
  void _saveConsent(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('consent', value);
  }

  // Method to handle the "Proceed" button
  void _onProceed() {
    if (isConsentGiven) {
      // Proceed to the next page or functionality
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LocationDetailsScreen(userId: widget.userId)),
      );
    } else {
      // Optionally show a message if the user has not agreed
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("يرجى الموافقة على الشروط والاحكام للمتابعة"),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[50], // Light blue background for water vibes
      appBar: AppBar(
        title: Text('الشروط والأحكام'),
        backgroundColor: Colors.blue[300], // Water-themed app bar color
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Text(
                    'الشروط والأحكام',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700], // Blue title to match the theme
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7), // Semi-transparent background
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      '1. الخدمات المقدمة:\n\n'
                          '- يتعهد الطرف الأول (مالك التطبيق) بتقديم خدمات الوساطة التقنية بين الطرف الثاني (مالك محطة تحلية المياه) والعميل المستفيد.\n'
                          '- يقتصر دور الطرف الأول على تنظيم العملية وربط العميل بالطرف الثاني، دون أي تدخل في تفاصيل تسليم المنتج أو جودة الخدمة المقدمة.\n\n'
                          '2. تفاصيل الطلب والتواصل:\n\n'
                          '- يتم توفير المعلومات الضرورية لتسهيل العملية، مثل معلومات العميل (الاسم، الموقع الجغرافي، الوقت المناسب للتوصيل، وطريقة الدفع).\n'
                          '- الطرف الثاني مسؤول عن ضمان جودة السلع وصلاحيتها، بما في ذلك المنتجات القابلة للتبديل أو الإرجاع.\n\n'
                          '3. الرسوم والعمولة:\n\n'
                          '- يتم اقتطاع عمولة مقدارها **0.6 قرش** على كل منتج يتم طلبه عبر النظام، ويتم حساب المستحقات للطرف الأول بناءً على عدد المنتجات المباعة.\n'
                          '- يُلزم الطرف الثاني بسداد العمولة المتراكمة للطرف الأول بشكل دوري (أسبوعي أو شهري) وفقًا للآلية التي يتم الاتفاق عليها بين الطرفين.\n\n'
                          '4. التأخر في السداد:\n\n'
                          '- في حالة تأخر الطرف الثاني عن سداد المستحقات في الوقت المحدد، يحق للطرف الأول تعليق أو إيقاف الخدمة مؤقتًا حتى يتم السداد.\n'
                          '- يُحتفظ للطرف الأول بحق إلغاء التعاون بشكل نهائي إذا تكرر التأخير أو استمر لفترة طويلة، مع إشعار الطرف الثاني قبل اتخاذ أي إجراء.\n\n'
                          '5. المسؤوليات:\n\n'
                          '- يتحمل الطرف الثاني المسؤولية الكاملة عن كافة الإجراءات المتعلقة بتوصيل الطلبات، جودة المنتجات، والالتزام بمتطلبات العملاء.\n'
                          '- لا يتحمل الطرف الأول أي مسؤولية قانونية أو تعويضية عن أي أخطاء أو مشاكل تحدث بين الطرف الثاني والعميل.\n\n'
                          '6. إلغاء الاتفاقية:\n\n'
                          '- يحق لأي من الطرفين إنهاء الاتفاقية بموجب إشعار كتابي يتم تقديمه قبل **30 يومًا** على الأقل، بشرط تصفية كافة المستحقات المالية.\n\n'
                          '7. التعديلات على الشروط:\n\n'
                          '- يحق للطرف الأول تعديل هذه الشروط والأحكام وفقًا لمتطلبات العمل، مع إشعار الطرف الثاني بأي تغييرات قبل **15 يومًا** من تطبيقها.\n'
                          '- استمرار استخدام الطرف الثاني للخدمة بعد التعديلات يُعتبر قبولاً صريحًا بالشروط الجديدة.\n\n'
                          '8. الموافقة:\n\n'
                          '- تعتبر الموافقة على هذه الشروط عبر التسجيل في النظام أو استخدام التطبيق بمثابة عقد اتفاقي ملزم للطرفين.\n',
                      style: TextStyle(fontSize: 16, color: Colors.blue[800]),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: isConsentGiven,
                  onChanged: (bool? value) {
                    setState(() {
                      isConsentGiven = value ?? false;
                    });
                    _saveConsent(isConsentGiven);
                  },
                ),
                Expanded(
                  child: Text(
                    'أوافق على الشروط والأحكام',
                    style: TextStyle(fontSize: 16, color: Colors.blue[800]),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _onProceed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[400], // Button color to match the theme
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('الموافقة والمتابعة'),
            ),
          ],
        ),
      ),
    );
  }
}
