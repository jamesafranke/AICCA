using InlineStrings
df.date = InlineString15.( Dates.format.(df.date, "yyyy-mm-dd") )
df.lat = InlineString7.(string.(df.lat))
df.lon = InlineString7.(string.(df.lon))