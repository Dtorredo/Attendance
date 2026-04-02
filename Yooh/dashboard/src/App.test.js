import { render, screen } from '@testing-library/react';
import App from './App';

test('renders Yooh title', () => {
  render(<App />);
  const titleElement = screen.getAllByText(/Yooh/i)[0];
  expect(titleElement).toBeInTheDocument();
});
