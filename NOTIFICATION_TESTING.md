# Push Notification Testing Guide

## Quick Test Commands

### Test Critical Error (Shows Dialog)
```bash
curl -X POST http://localhost:8000/api/v1/webhooks/n8n-error \
  -H "Content-Type: application/json" \
  -d '{
    "executionId": "test_critical_123",
    "workflowId": "wf_456",
    "instanceId": "YOUR_INSTANCE_ID",
    "workflowName": "Critical Database Sync",
    "error": {
      "message": "Critical: Database connection lost - immediate action required"
    }
  }'
```

### Test Warning (Shows Orange SnackBar)
```bash
curl -X POST http://localhost:8000/api/v1/webhooks/n8n-error \
  -H "Content-Type: application/json" \
  -d '{
    "executionId": "test_warning_456",
    "workflowId": "wf_789",
    "instanceId": "YOUR_INSTANCE_ID",
    "workflowName": "API Rate Limiter",
    "error": {
      "message": "Warning: API rate limit approaching 80%"
    }
  }'
```

### Test Info (Shows Blue SnackBar)
```bash
curl -X POST http://localhost:8000/api/v1/webhooks/n8n-error \
  -H "Content-Type: application/json" \
  -d '{
    "executionId": "test_info_789",
    "workflowId": "wf_abc",
    "instanceId": "YOUR_INSTANCE_ID",
    "workflowName": "Batch Processor",
    "error": {
      "message": "Info: Workflow completed with minor warnings"
    }
  }'
```

## Visual Test Results

### Critical/Error Severity
**Expected Result:**
```
┌─────────────────────────────────┐
│         [!] Icon (Red)          │
│   🚨 Critical Workflow Error    │
│                                 │
│  Database connection lost       │
│                                 │
│  ┌─────────────────────────┐   │
│  │⚠️ Requires immediate    │   │
│  │   attention             │   │
│  └─────────────────────────┘   │
│                                 │
│  [Dismiss]    [View Details]   │
└─────────────────────────────────┘
```

### Warning Severity
**Expected Result:**
```
┌─────────────────────────────────┐
│ App Content                     │
│                                 │
│  ┌──────────────────────────┐  │
│  │⚠️  API rate limit        │  │
│  │    approaching 80%  [View]│  │
│  └──────────────────────────┘  │
└─────────────────────────────────┘
     (Orange SnackBar)
```

### Info Severity
**Expected Result:**
```
┌─────────────────────────────────┐
│ App Content                     │
│                                 │
│  ┌──────────────────────────┐  │
│  │ℹ️  Completed with        │  │
│  │    warnings         [View]│  │
│  └──────────────────────────┘  │
└─────────────────────────────────┘
     (Blue SnackBar)
```

## Test Scenarios

### Scenario 1: App in Foreground
1. **Setup:** Open FlowDash app and keep it visible
2. **Action:** Send test notification using curl command
3. **Expected:**
   - Critical/Error → Dialog appears immediately
   - Warning → Orange SnackBar at bottom
   - Info → Blue SnackBar at bottom
4. **Verify:**
   - Tap "View Details" → Opens execution details bottom sheet
   - Tap "Dismiss" → Dialog closes

### Scenario 2: App in Background
1. **Setup:** Open app, then minimize (home button)
2. **Action:** Send test notification
3. **Expected:**
   - System notification appears in notification tray
   - Notification shows workflow name and error
4. **Verify:**
   - Tap notification → App opens
   - Execution details bottom sheet appears

### Scenario 3: App Terminated
1. **Setup:** Force close the app completely
2. **Action:** Send test notification
3. **Expected:**
   - System notification appears in notification tray
4. **Verify:**
   - Tap notification → App starts
   - Execution details bottom sheet appears

## Checklist

### Before Testing
- [ ] Backend is running (`make run-dev`)
- [ ] Mobile app has notification permissions
- [ ] User has created at least one instance
- [ ] FCM token is stored in Firestore
- [ ] Replace `YOUR_INSTANCE_ID` in curl commands

### During Testing
- [ ] Test all three app states (foreground, background, terminated)
- [ ] Test all severity levels (critical, error, warning, info)
- [ ] Verify deep linking works (tapping notification opens details)
- [ ] Verify dialog dismissal works
- [ ] Verify SnackBar auto-dismiss (6 seconds)

### After Testing
- [ ] Check backend logs for FCM success
- [ ] Check mobile logs for notification receipt
- [ ] Verify execution details load correctly
- [ ] Check that navigation back works properly

## Troubleshooting

### Notification Not Appearing
```bash
# Check if FCM token exists
firebase firestore:get fcm_tokens/YOUR_USER_ID

# Check backend logs
docker-compose -f docker-compose.dev.yml logs -f api

# Check mobile logs
flutter logs
```

### Wrong Notification Style
```python
# Backend determines severity in webhook_handler.py
# Add debug logging:
print(f"Severity determined: {severity}")
```

### Deep Link Not Working
```dart
// Check mobile logs for:
// "_navigateFromMessage: execution_id=xxx, instance_id=xxx"
// If missing, instance_id not in payload
```

## Advanced: Custom Severity Rules

Edit `flowdash-backend/app/notifier/webhook_handler.py`:

```python
# Add custom severity logic
error_message = error.get("message", "Unknown error")

# Pattern matching
if "critical" in error_message.lower():
    severity = "critical"
elif "timeout" in error_message.lower():
    severity = "error"
elif "warning" in error_message.lower():
    severity = "warning"
else:
    severity = "info"
```

## Performance Notes

- ✅ Notifications sent asynchronously (non-blocking)
- ✅ Dialog shown immediately on receive
- ✅ SnackBar queued if multiple notifications
- ✅ Deep linking cached until app ready
- ✅ No network calls on tap (data in payload)




