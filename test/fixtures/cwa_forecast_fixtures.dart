/// 測試用 CWA F-C0032-001 JSON 字面常數。
///
/// 結構對應 `format=JSON` 的實際回應：頂層 `success` + `records.location[]`，
/// 時間字串為 `"YYYY-MM-DD HH:MM:SS"`（無 T、無時區）。
library;

const String taipeiSuccessJson = '''
{
  "success": "true",
  "result": {
    "resource_id": "F-C0032-001",
    "fields": []
  },
  "records": {
    "datasetDescription": "三十六小時天氣預報",
    "location": [
      {
        "locationName": "臺北市",
        "weatherElement": [
          {
            "elementName": "Wx",
            "time": [
              {"startTime":"2026-05-22 12:00:00","endTime":"2026-05-22 18:00:00","parameter":{"parameterName":"晴時多雲","parameterValue":"2"}},
              {"startTime":"2026-05-22 18:00:00","endTime":"2026-05-23 06:00:00","parameter":{"parameterName":"多雲","parameterValue":"4"}},
              {"startTime":"2026-05-23 06:00:00","endTime":"2026-05-23 18:00:00","parameter":{"parameterName":"陰短暫雨","parameterValue":"12"}}
            ]
          },
          {
            "elementName": "PoP",
            "time": [
              {"startTime":"2026-05-22 12:00:00","endTime":"2026-05-22 18:00:00","parameter":{"parameterName":"10","parameterUnit":"百分比"}},
              {"startTime":"2026-05-22 18:00:00","endTime":"2026-05-23 06:00:00","parameter":{"parameterName":"20","parameterUnit":"百分比"}},
              {"startTime":"2026-05-23 06:00:00","endTime":"2026-05-23 18:00:00","parameter":{"parameterName":"70","parameterUnit":"百分比"}}
            ]
          },
          {
            "elementName": "MinT",
            "time": [
              {"startTime":"2026-05-22 12:00:00","endTime":"2026-05-22 18:00:00","parameter":{"parameterName":"24","parameterUnit":"C"}},
              {"startTime":"2026-05-22 18:00:00","endTime":"2026-05-23 06:00:00","parameter":{"parameterName":"22","parameterUnit":"C"}},
              {"startTime":"2026-05-23 06:00:00","endTime":"2026-05-23 18:00:00","parameter":{"parameterName":"23","parameterUnit":"C"}}
            ]
          },
          {
            "elementName": "CI",
            "time": [
              {"startTime":"2026-05-22 12:00:00","endTime":"2026-05-22 18:00:00","parameter":{"parameterName":"舒適"}},
              {"startTime":"2026-05-22 18:00:00","endTime":"2026-05-23 06:00:00","parameter":{"parameterName":"舒適"}},
              {"startTime":"2026-05-23 06:00:00","endTime":"2026-05-23 18:00:00","parameter":{"parameterName":"稍有寒意至舒適"}}
            ]
          },
          {
            "elementName": "MaxT",
            "time": [
              {"startTime":"2026-05-22 12:00:00","endTime":"2026-05-22 18:00:00","parameter":{"parameterName":"30","parameterUnit":"C"}},
              {"startTime":"2026-05-22 18:00:00","endTime":"2026-05-23 06:00:00","parameter":{"parameterName":"26","parameterUnit":"C"}},
              {"startTime":"2026-05-23 06:00:00","endTime":"2026-05-23 18:00:00","parameter":{"parameterName":"27","parameterUnit":"C"}}
            ]
          }
        ]
      }
    ]
  }
}
''';

/// CWA 防禦情境：HTTP 200 但 `success="false"`（實測時 token 錯為 401，但
/// 其他錯誤如 rate limit / 參數錯有可能落在此分支）。
const String authFailureJson = '''
{
  "success": "false",
  "result": {
    "resource_id": "F-C0032-001",
    "fields": []
  }
}
''';

/// 找不到城市時 CWA 仍回 `success="true"` + 空 `records.location[]`。
const String emptyLocationsJson = '''
{
  "success": "true",
  "records": {
    "datasetDescription": "三十六小時天氣預報",
    "location": []
  }
}
''';

/// 缺少 records 整段（格式錯誤）。
const String malformedNoRecordsJson = '''
{
  "success": "true"
}
''';

/// 兩個城市的成功回應，用於測試「瀏覽模式」（不帶 locationName）。
const String twoCitiesSuccessJson = '''
{
  "success": "true",
  "records": {
    "location": [
      {
        "locationName": "臺北市",
        "weatherElement": [
          {"elementName":"Wx","time":[{"startTime":"2026-05-22 12:00:00","endTime":"2026-05-22 18:00:00","parameter":{"parameterName":"晴","parameterValue":"1"}}]},
          {"elementName":"PoP","time":[{"startTime":"2026-05-22 12:00:00","endTime":"2026-05-22 18:00:00","parameter":{"parameterName":"10","parameterUnit":"百分比"}}]},
          {"elementName":"MinT","time":[{"startTime":"2026-05-22 12:00:00","endTime":"2026-05-22 18:00:00","parameter":{"parameterName":"24","parameterUnit":"C"}}]},
          {"elementName":"MaxT","time":[{"startTime":"2026-05-22 12:00:00","endTime":"2026-05-22 18:00:00","parameter":{"parameterName":"30","parameterUnit":"C"}}]},
          {"elementName":"CI","time":[{"startTime":"2026-05-22 12:00:00","endTime":"2026-05-22 18:00:00","parameter":{"parameterName":"舒適"}}]}
        ]
      },
      {
        "locationName": "高雄市",
        "weatherElement": [
          {"elementName":"Wx","time":[{"startTime":"2026-05-22 12:00:00","endTime":"2026-05-22 18:00:00","parameter":{"parameterName":"多雲","parameterValue":"4"}}]},
          {"elementName":"PoP","time":[{"startTime":"2026-05-22 12:00:00","endTime":"2026-05-22 18:00:00","parameter":{"parameterName":"30","parameterUnit":"百分比"}}]},
          {"elementName":"MinT","time":[{"startTime":"2026-05-22 12:00:00","endTime":"2026-05-22 18:00:00","parameter":{"parameterName":"27","parameterUnit":"C"}}]},
          {"elementName":"MaxT","time":[{"startTime":"2026-05-22 12:00:00","endTime":"2026-05-22 18:00:00","parameter":{"parameterName":"33","parameterUnit":"C"}}]},
          {"elementName":"CI","time":[{"startTime":"2026-05-22 12:00:00","endTime":"2026-05-22 18:00:00","parameter":{"parameterName":"悶熱"}}]}
        ]
      }
    ]
  }
}
''';

/// MinT 數值非數字字串（單一時段，方便聚焦測試）。
const String malformedNonNumericMinTJson = '''
{
  "success": "true",
  "records": {
    "location": [
      {
        "locationName": "臺北市",
        "weatherElement": [
          {"elementName":"Wx","time":[{"startTime":"2026-05-22 12:00:00","endTime":"2026-05-22 18:00:00","parameter":{"parameterName":"晴","parameterValue":"1"}}]},
          {"elementName":"PoP","time":[{"startTime":"2026-05-22 12:00:00","endTime":"2026-05-22 18:00:00","parameter":{"parameterName":"10","parameterUnit":"百分比"}}]},
          {"elementName":"MinT","time":[{"startTime":"2026-05-22 12:00:00","endTime":"2026-05-22 18:00:00","parameter":{"parameterName":"abc","parameterUnit":"C"}}]},
          {"elementName":"MaxT","time":[{"startTime":"2026-05-22 12:00:00","endTime":"2026-05-22 18:00:00","parameter":{"parameterName":"30","parameterUnit":"C"}}]},
          {"elementName":"CI","time":[{"startTime":"2026-05-22 12:00:00","endTime":"2026-05-22 18:00:00","parameter":{"parameterName":"舒適"}}]}
        ]
      }
    ]
  }
}
''';
