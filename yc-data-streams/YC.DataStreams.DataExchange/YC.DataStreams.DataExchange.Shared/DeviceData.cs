namespace YC.DataStreams.DataExchange.Shared
{
    public class DeviceData
    {
        public string DeviceId { get; set; }
        public int Humidity { get; set; }
        public int Temperature { get; set; }

        public static List<DeviceData> RandomDeviceList()
        {
            List<DeviceData> dataList = new();
            int _deviceCount = 1;
            for (var i = 0; i < _deviceCount; i++)
            {
                var rnd = new Random(Guid.NewGuid().GetHashCode());
                var data = new DeviceData
                {
                    DeviceId = string.Format("Device{0}", i),
                    Temperature = rnd.Next(0, 100),
                    Humidity = rnd.Next(0, 200)
                };
                dataList.Add(data);
            }
            return dataList;
        }

        public override string ToString()
        {
            return $"{DeviceId}: {Humidity} RH; {Temperature} К.";
        }
    }
}
