using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Twilio;
using Twilio.Rest.Api.V2010.Account;

namespace ConvertAlertToPhoneCall
{
    public static class ConvertAlertToPhoneCall
    {
        [FunctionName("ConvertAlertToPhoneCall")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = null)] HttpRequest req,
            ILogger log)
        {
            // Get the details of the alert, which come from the request body.
            string requestBody = string.Empty;
            using (StreamReader streamReader = new StreamReader(req.Body))
            {
                requestBody = await streamReader.ReadToEndAsync();
            }

            dynamic alert = JObject.Parse(requestBody);
            var severity = GetSeverityDescription((string)alert.data.essentials.severity);
            var alertType = (string)alert.data.essentials.signalType;
            var alertName = (string)alert.data.essentials.alertRule;

            // Ignore alert resolutions.
            if (alert.data.essentials.monitorCondition == "Resolved")
            {
                log.LogInformation("Received alert resolution; ignoring.");
            }

            // Initialise the Twilio client.
            var accountSid = Environment.GetEnvironmentVariable("TwilioAccountSid");
            var authToken = Environment.GetEnvironmentVariable("TwilioAuthToken");
            var fromNumber = Environment.GetEnvironmentVariable("TwilioFromNumber");
            var toNumber = Environment.GetEnvironmentVariable("TwilioToNumber");
            TwilioClient.Init(accountSid, authToken);

            // Prepare the Twiml request, which is the Twilio markup to specify the voice message.
            var message = $"A {severity} Azure Monitor {alertType} alert has been fired. The alert rule name is {alertName}.";
            var twiml = $"<Response><Say>${message}</Say></Response>";
            log.LogInformation($"Twiml request prepared: {twiml}");

            // Initiate the phone call.
            var call = CallResource.Create(
                twiml: new Twilio.Types.Twiml(twiml),
                to: new Twilio.Types.PhoneNumber(toNumber),
                from: new Twilio.Types.PhoneNumber(fromNumber)
            );
            log.LogInformation($"Call request submitted and was given the Sid {call.Sid}.");

            return new OkResult();
        }

        private static string GetSeverityDescription(string severityCode)
        {
            switch (severityCode)
            {
                case "Sev1":
                    return "Severity 1";
                case "Sev2":
                    return "Severity 2";
                case "Sev3":
                    return "Severity 3";
                case "Sev4":
                    return "Severity 4";
                default:
                    return severityCode;
            }
        }
    }
}
