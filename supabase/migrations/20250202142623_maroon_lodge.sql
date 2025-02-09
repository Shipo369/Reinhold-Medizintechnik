-- Clean up existing certificate requests
TRUNCATE certificate_requests CASCADE;

-- Reset any sequences associated with the table
ALTER SEQUENCE IF EXISTS certificate_requests_id_seq RESTART;