using Contentful.Core;
using System;


namespace Contentful.Data
{
    public class ContentfulService
    {

        public async Task<CarData[]> GetCarDataAsync(DateTime startDate) { 
            string apikey = "";
            string space = "";
            if (!string.IsNullOrEmpty(Environment.GetEnvironmentVariable("CONTENTFUL_APIKEY")))
                apikey = Environment.GetEnvironmentVariable("CONTENTFUL_APIKEY");
            if (!string.IsNullOrEmpty(Environment.GetEnvironmentVariable("CONTENTFUL_SPACE")))
                space = Environment.GetEnvironmentVariable("CONTENTFUL_SPACE");
            var httpClient = new HttpClient();
            var client = new ContentfulClient(httpClient, apikey, null, space);
            var entries = await client.GetEntries<CarData>();
            return entries.ToArray();
        }
    }
}