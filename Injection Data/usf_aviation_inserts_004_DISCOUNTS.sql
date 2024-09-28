--INSERT TABLE [discounts]

INSERT [dbo].[discounts] ([discount_id], [name], [percentage], [observations], [start_date], [end_date]) VALUES (1, N'Student Discount', CAST(0.20 AS Decimal(5, 2)), N'Show student ID. Age between 16 and 23', CAST(N'2021-01-01' AS Date), NULL)
GO
INSERT [dbo].[discounts] ([discount_id], [name], [percentage], [observations], [start_date], [end_date]) VALUES (2, N'Elderly Discount', CAST(0.15 AS Decimal(5, 2)), N'Show ID. Age at least 65', CAST(N'2021-01-01' AS Date), NULL)
GO
INSERT [dbo].[discounts] ([discount_id], [name], [percentage], [observations], [start_date], [end_date]) VALUES (3, N'Courtesy Discount', CAST(1.00 AS Decimal(5, 2)), N'Authorization required', CAST(N'2021-01-01' AS Date), NULL)
GO
INSERT [dbo].[discounts] ([discount_id], [name], [percentage], [observations], [start_date], [end_date]) VALUES (4, N'Amazon Prime Customers Discount', CAST(0.25 AS Decimal(5, 2)), N'Validate Prime membership', CAST(N'2021-01-01' AS Date), NULL)
GO
