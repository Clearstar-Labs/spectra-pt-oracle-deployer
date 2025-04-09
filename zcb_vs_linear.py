import numpy as np
import matplotlib.pyplot as plt

# Constants
SECONDS_PER_YEAR = 365 * 24 * 60 * 60  # 31,536,000 seconds

def calculate_prices(initial_apy_percent, maturity_days):
    # Convert inputs
    initial_apy = initial_apy_percent / 100  # Convert % to decimal
    maturity_seconds = maturity_days * 24 * 60 * 60
    
    # Create time array from maturity to issuance (reverse timeline)
    time_left = np.linspace(maturity_seconds, 0, 1000)
    t_years = time_left / SECONDS_PER_YEAR

    # Zero Coupon Bond Model calculations (autocompounded)
    zero_coupon_prices = 1 / ((1 + initial_apy) ** t_years)

    # Linear Discount Model calculations
    linear_prices = 1 - (initial_apy * t_years)
    linear_prices = np.maximum(linear_prices, 0)  # Prevent negative prices

    return time_left, zero_coupon_prices, linear_prices

def plot_results(time_left, zero_coupon, linear, maturity_days, apy_percent):
    plt.figure(figsize=(10, 6))
    
    # Convert time left to percentage of total maturity
    time_left_pct = (time_left / (maturity_days * 24 * 60 * 60)) * 100
    
    plt.plot(time_left_pct, zero_coupon, label='Zero Coupon (Autocompounded)')
    plt.plot(time_left_pct, linear, label='Linear Discount', linestyle='--')
    
    plt.title(f'PT Token Pricing Models Comparison ({apy_percent}% APY, {maturity_days}-Day Maturity)')
    plt.xlabel('Time Remaining Until Maturity (%)')
    plt.ylabel('Price (Normalized to Future Value)')
    plt.legend()
    plt.grid(True)
    
    # Invert x-axis to show countdown to maturity
    plt.gca().invert_xaxis()
    plt.show()

# Example usage
APY_PERCENT = 50  # 10% APY
MATURITY_DAYS = 365  # 1-year maturity

time_left, zero_coupon, linear = calculate_prices(APY_PERCENT, MATURITY_DAYS)
plot_results(time_left, zero_coupon, linear, MATURITY_DAYS, APY_PERCENT)